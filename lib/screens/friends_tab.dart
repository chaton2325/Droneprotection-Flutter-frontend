import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../state/friend_live_location_provider.dart';
import '../state/friends_provider.dart';
import '../theme/app_theme.dart';
import '../utils/maps_launcher.dart';
import '../utils/time.dart';

/// Modal de resultat (succes/echec) affiche apres une action sur une
/// relation d'amitie, pour ne pas compter uniquement sur le bandeau discret
/// errorMessage en haut de l'onglet.
Future<void> _showResultDialog(
  BuildContext context, {
  required bool success,
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      icon: Icon(
        success ? Icons.check_circle_rounded : Icons.error_rounded,
        color: success ? AppColors.ok500 : AppColors.brand500,
        size: 40,
      ),
      title: Text(title),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Demande de confirmation avant une action difficile a annuler (retirer un
/// ami, refuser/annuler une demande) : retourne true seulement si l'action a
/// ete confirmee.
Future<bool> _confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(title),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Retour'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand600),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<void> _acceptRequest(BuildContext context, FriendRequest request) async {
  final error = await context.read<FriendsProvider>().accept(request.id);
  if (!context.mounted) return;
  await _showResultDialog(
    context,
    success: error == null,
    title: error == null ? 'Demande acceptee' : "Echec",
    message:
        error ?? 'Vous etes maintenant amis avec ${request.person.fullName}.',
  );
}

Future<void> _declineRequest(BuildContext context, FriendRequest request) async {
  final confirmed = await _confirmDialog(
    context,
    title: 'Refuser cette demande ?',
    message:
        '${request.person.fullName} ne sera pas ajoute(e) a vos amis.',
    confirmLabel: 'Refuser',
  );
  if (!confirmed || !context.mounted) return;

  final error = await context.read<FriendsProvider>().cancelOrDecline(
    request.id,
  );
  if (error != null && context.mounted) {
    await _showResultDialog(context, success: false, title: 'Echec', message: error);
  }
}

Future<void> _cancelRequest(BuildContext context, FriendRequest request) async {
  final confirmed = await _confirmDialog(
    context,
    title: 'Annuler cette demande ?',
    message:
        'La demande envoyee a ${request.person.fullName} sera annulee.',
    confirmLabel: 'Annuler la demande',
  );
  if (!confirmed || !context.mounted) return;

  final error = await context.read<FriendsProvider>().cancelOrDecline(
    request.id,
  );
  if (error != null && context.mounted) {
    await _showResultDialog(context, success: false, title: 'Echec', message: error);
  }
}

/// Onglet "Amis" de la barre de navigation principale (voir RootShell).
/// Regroupe la liste des amis, les demandes en attente et la recherche dans
/// trois sous-onglets pour eviter le long scroll unique de l'ancien ecran
/// accessible depuis les reglages.
class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmRemove(Friend friend) async {
    final confirmed = await _confirmDialog(
      context,
      title: 'Retirer cet ami ?',
      message:
          '${friend.fullName} ne sera plus dans votre liste d\'amis et ne '
          'verra plus votre position en cas d\'alerte.',
      confirmLabel: 'Retirer',
    );
    if (!confirmed || !mounted) return;

    final error = await context.read<FriendsProvider>().removeFriend(friend);
    if (error != null && mounted) {
      await _showResultDialog(
        context,
        success: false,
        title: 'Echec',
        message: error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsProvider>();
    final pendingCount = friends.incoming.length;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.brand500.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashBorderRadius: BorderRadius.circular(11),
            labelColor: AppColors.brand400,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'Amis (${friends.friends.length})'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Demandes'),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand500,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Ajouter'),
            ],
          ),
        ),
        if (friends.errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brand500.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.brand500.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                friends.errorMessage!,
                style: const TextStyle(color: AppColors.brand400, fontSize: 13),
              ),
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FriendsListView(friends: friends, onRemove: _confirmRemove),
              _RequestsView(friends: friends),
              _AddFriendView(friends: friends, searchCtrl: _searchCtrl),
            ],
          ),
        ),
      ],
    );
  }
}

class _FriendsListView extends StatelessWidget {
  final FriendsProvider friends;
  final void Function(Friend) onRemove;
  const _FriendsListView({required this.friends, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final liveLocations = context.watch<FriendLiveLocationProvider>();

    Widget child;
    if (friends.loading && friends.friends.isEmpty) {
      child = const Center(
        child: CircularProgressIndicator(color: AppColors.brand500),
      );
    } else if (friends.friends.isEmpty) {
      child = ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _EmptyState(
            icon: Icons.people_outline_rounded,
            message:
                "Aucun ami pour le moment.\nAjoutez des proches depuis l'onglet Ajouter.",
          ),
        ],
      );
    } else {
      child = ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: friends.friends.length,
        itemBuilder: (context, index) {
          final person = friends.friends[index];
          final live = liveLocations.forFriend(person.id);
          return _PersonTile(
            person: person,
            subtitle: live != null ? 'Position partagee en direct' : null,
            subtitleColor: live != null ? AppColors.ok400 : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (live != null)
                  IconButton(
                    tooltip: 'Itineraire',
                    icon: const Icon(
                      Icons.near_me_rounded,
                      color: AppColors.ok400,
                    ),
                    onPressed: () => openInMaps(
                      context,
                      latitude: live.latitude,
                      longitude: live.longitude,
                      directions: true,
                    ),
                  ),
                PopupMenuButton<String>(
                  tooltip: 'Options',
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                  ),
                  color: AppColors.surface2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onSelected: (value) {
                    if (value == 'remove') onRemove(person);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_remove_rounded,
                            size: 18,
                            color: AppColors.brand400,
                          ),
                          SizedBox(width: 10),
                          Text('Retirer'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.brand500,
      onRefresh: friends.load,
      child: child,
    );
  }
}

class _RequestsView extends StatelessWidget {
  final FriendsProvider friends;
  const _RequestsView({required this.friends});

  @override
  Widget build(BuildContext context) {
    final hasNothing = friends.incoming.isEmpty && friends.outgoing.isEmpty;

    return RefreshIndicator(
      color: AppColors.brand500,
      onRefresh: friends.load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (hasNothing && !friends.loading)
            const _EmptyState(
              icon: Icons.inbox_rounded,
              message: 'Aucune demande en attente.',
            ),
          if (friends.incoming.isNotEmpty) ...[
            const _SectionTitle('Demandes recues'),
            ...friends.incoming.map(
              (request) => _PersonTile(
                person: request.person,
                subtitle: timeAgo(request.createdAt),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.ok500,
                      ),
                      onPressed: () => _acceptRequest(context, request),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: AppColors.brand400,
                      ),
                      onPressed: () => _declineRequest(context, request),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (friends.outgoing.isNotEmpty) ...[
            const _SectionTitle('Demandes envoyees'),
            ...friends.outgoing.map(
              (request) => _PersonTile(
                person: request.person,
                subtitle: 'En attente - ${timeAgo(request.createdAt)}',
                trailing: TextButton(
                  onPressed: () => _cancelRequest(context, request),
                  child: const Text('Annuler'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddFriendView extends StatefulWidget {
  final FriendsProvider friends;
  final TextEditingController searchCtrl;
  const _AddFriendView({required this.friends, required this.searchCtrl});

  @override
  State<_AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<_AddFriendView> {
  Timer? _searchDebounce;

  // Ids en cours d'envoi : desactive le bouton et affiche un spinner pour
  // eviter un double-clic qui enverrait la demande deux fois.
  final Set<int> _sendingIds = {};

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => context.read<FriendsProvider>().search(value),
    );
  }

  Future<void> _sendRequest(Friend person) async {
    setState(() => _sendingIds.add(person.id));
    final error = await context.read<FriendsProvider>().sendRequest(
      person.username,
    );
    if (!mounted) return;
    setState(() => _sendingIds.remove(person.id));

    final success = error == null;
    await _showResultDialog(
      context,
      success: success,
      title: success ? 'Demande envoyee' : "Echec de l'envoi",
      message: success
          ? '@${person.username} recevra votre demande. Vous serez amis '
                'des qu\'elle sera acceptee.'
          : error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final friends = widget.friends;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: widget.searchCtrl,
          decoration: const InputDecoration(
            labelText: "Ajouter par @nom d'utilisateur",
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (value) {
            setState(() {}); // rafraichit l'etat vide/resultats immediatement
            _onSearchChanged(value);
          },
        ),
        const SizedBox(height: 16),
        if (widget.searchCtrl.text.trim().isEmpty)
          const _EmptyState(
            icon: Icons.person_search_rounded,
            message: "Recherchez un proche par son @nom d'utilisateur.",
          )
        else if (friends.searching)
          const Center(
            child: CircularProgressIndicator(color: AppColors.brand500),
          )
        else if (friends.searchResults.isEmpty)
          const _EmptyState(
            icon: Icons.person_off_rounded,
            message:
                'Aucun utilisateur trouve (ou deja dans vos amis/demandes).',
          )
        else
          ...friends.searchResults.map(
            (person) => _PersonTile(
              person: person,
              trailing: TextButton(
                onPressed: _sendingIds.contains(person.id)
                    ? null
                    : () => _sendRequest(person),
                child: _sendingIds.contains(person.id)
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ajouter'),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final Friend person;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;

  const _PersonTile({
    required this.person,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = AppConfig.resolveAvatarUrl(person.avatarUrl);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.brand500.withValues(alpha: 0.15),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(person.fullName.isNotEmpty ? person.fullName[0].toUpperCase() : '?')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  subtitle ?? '@${person.username}',
                  style: TextStyle(
                    color: subtitleColor ?? AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: subtitleColor != null ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
