import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../models/friend.dart';
import '../state/friends_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Amis et famille')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: friends.load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: "Ajouter par @nom d'utilisateur",
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) => context.read<FriendsProvider>().search(value),
              ),
              if (friends.searching) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
              ...friends.searchResults.map(
                (person) => _PersonTile(
                  person: person,
                  trailing: TextButton(
                    onPressed: () =>
                        context.read<FriendsProvider>().sendRequest(person.username),
                    child: const Text('Ajouter'),
                  ),
                ),
              ),
              if (friends.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brand500.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.brand500.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    friends.errorMessage!,
                    style: const TextStyle(color: AppColors.brand400, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 28),
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
                          icon: const Icon(Icons.check_circle_rounded, color: AppColors.ok500),
                          onPressed: () =>
                              context.read<FriendsProvider>().accept(request.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, color: AppColors.brand400),
                          onPressed: () => context
                              .read<FriendsProvider>()
                              .cancelOrDecline(request.id),
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
                      onPressed: () =>
                          context.read<FriendsProvider>().cancelOrDecline(request.id),
                      child: const Text('Annuler'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _SectionTitle('Mes amis (${friends.friends.length})'),
              if (friends.loading && friends.friends.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (friends.friends.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aucun ami pour le moment.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...friends.friends.map((person) => _PersonTile(person: person)),
            ],
          ),
        ),
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
  final Widget? trailing;

  const _PersonTile({required this.person, this.subtitle, this.trailing});

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
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
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
