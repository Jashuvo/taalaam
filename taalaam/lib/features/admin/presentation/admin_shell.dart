import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const AdminShell({
    required this.child,
    required this.currentLocation,
    super.key,
  });

  int get _selectedIndex {
    if (currentLocation.startsWith('/admin/users')) return 3;
    if (currentLocation.startsWith('/admin/upload')) return 2;
    if (currentLocation.startsWith('/admin/review')) return 1;
    return 0; // /admin → dashboard
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/admin');
      case 1: context.go('/admin/review');
      case 2: context.go('/admin/upload');
      case 3: context.go('/admin/users');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final adminEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    final navItems = [
      (icon: Icons.dashboard_outlined,   active: Icons.dashboard,        label: 'Dashboard'),
      (icon: Icons.rate_review_outlined,  active: Icons.rate_review,      label: 'Content'),
      (icon: Icons.upload_file_outlined,  active: Icons.upload_file,      label: 'Upload'),
      (icon: Icons.people_outline,        active: Icons.people,           label: 'Users'),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: Row(
        children: [
          // ── Navigation Rail ──────────────────────────────────────────
          Container(
            width: isWide ? 200 : 72,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              border: Border(right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: logo + app name
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.mosque_outlined, size: 20, color: cs.onPrimaryContainer),
                      ),
                      if (isWide) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ta'allam", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              Text('Admin CMS', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 8),

                // Nav items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: navItems.length,
                    itemBuilder: (ctx, i) {
                      final item = navItems[i];
                      final isSelected = _selectedIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () => _navigate(context, i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 12 : 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primaryContainer.withValues(alpha: 0.7)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: isWide
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected ? item.active : item.icon,
                                    size: 20,
                                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                                  ),
                                  if (isWide) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      item.label,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected ? cs.primary : cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer: user info + logout
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: isWide
                      ? Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: cs.primaryContainer,
                              child: Icon(Icons.person_outline, size: 16, color: cs.onPrimaryContainer),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                adminEmail,
                                style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.logout, size: 16, color: cs.onSurfaceVariant),
                              tooltip: 'Sign out',
                              visualDensity: VisualDensity.compact,
                              onPressed: () async {
                                await Supabase.instance.client.auth.signOut();
                                if (context.mounted) context.go('/login');
                              },
                            ),
                          ],
                        )
                      : IconButton(
                          icon: Icon(Icons.logout, size: 18, color: cs.onSurfaceVariant),
                          tooltip: 'Sign out',
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                ),
              ],
            ),
          ),

          // ── Page content ─────────────────────────────────────────────
          Expanded(child: child),
        ],
      ),
    );
  }
}
