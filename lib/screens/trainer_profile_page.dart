import 'package:flutter/material.dart';
import '../utils/app_text_style.dart';
import '../services/profile_store.dart';
import '../services/mock_api.dart';
import '../models/er_models.dart';
import 'trainer_profile_edit_page.dart';

class TrainerProfilePage extends StatefulWidget {
  const TrainerProfilePage({super.key});

  @override
  State<TrainerProfilePage> createState() => _TrainerProfilePageState();
}

class _TrainerProfilePageState extends State<TrainerProfilePage> {
  late Future<TrainerProfileModel> _future;

  @override
  void initState() {
    super.initState();
    _future = const MockApiService().fetchTrainerProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
                Positioned(
                  right: 8,
                  top: 10,
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                )
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F7F7),
      body: FutureBuilder<TrainerProfileModel>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snapshot.data!;
          // keep ProfileStore in sync for edit screen defaults
          ProfileStore.trainer
            ..name = p.name
            ..title = p.title
            ..bio = p.bio
            ..email = p.email
            ..phone = p.phone
            ..location = p.location
            ..clients = p.clients
            ..plans = p.plans
            ..rating = p.rating;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(onEdit: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const TrainerProfileEditPage()),
                );
                if (saved == true) setState(() => _future = const MockApiService().fetchTrainerProfile());
              }),
              const SizedBox(height: 16),
              _ContactCard(),
              const SizedBox(height: 16),
              _AchievementsRow(),
              const SizedBox(height: 16),
              _CertificationsCard(),
              const SizedBox(height: 16),
              _SpecializationsCard(),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({this.onEdit});
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) {
    final p = ProfileStore.trainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF42E695), Color(0xFF3BB2B8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=300&h=300&fit=crop'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: AppTextStyle.semiBoldText(size: 18, color: Colors.white)),
                const SizedBox(height: 2),
                Text(p.title, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text('${p.rating.toStringAsFixed(1)} (127 reviews)', style: const TextStyle(color: Colors.white)),
                ]),
              ]),
            ),
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, color: Colors.white))
          ],
        ),
        const SizedBox(height: 12),
        Text(ProfileStore.trainer.bio, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 14),
        Row(children: [
          _StatTile(icon: Icons.groups, label: 'Clients', value: ProfileStore.trainer.clients.toString()),
          const SizedBox(width: 10),
          _StatTile(icon: Icons.rule_folder, label: 'Plans', value: ProfileStore.trainer.plans.toString()),
          const SizedBox(width: 10),
          _StatTile(icon: Icons.star_rate_rounded, label: 'Rating', value: ProfileStore.trainer.rating.toStringAsFixed(1)),
        ])
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white)),
        ]),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String title, String value) => Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.grey[700]),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyle.mediumText(size: 12, color: Colors.grey[700])),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyle.semiBoldText(size: 14, color: Colors.black)),
          ]))
        ]);

    final p = ProfileStore.trainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Contact Information', style: AppTextStyle.semiBoldText(size: 16, color: Colors.black)),
        const SizedBox(height: 12),
        row(Icons.alternate_email, 'Email', p.email),
        const SizedBox(height: 12),
        row(Icons.phone_in_talk, 'Phone', p.phone),
        const SizedBox(height: 12),
        row(Icons.location_on, 'Location', p.location),
      ]),
    );
  }
}

class _AchievementsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget tile(String title, String value, String sub) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
            ]),
            child: Column(children: [
              const Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(height: 6),
              Text(value, style: AppTextStyle.semiBoldText(size: 18, color: Colors.black)),
              const SizedBox(height: 2),
              Text(sub, textAlign: TextAlign.center, style: AppTextStyle.regularText(size: 12, color: Colors.grey[700])),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Achievements', style: AppTextStyle.semiBoldText(size: 16, color: Colors.black)),
      const SizedBox(height: 12),
      Row(children: [
        tile('Success Stories', '142', '100+\nSuccess\nStories'),
        const SizedBox(width: 12),
        tile('Client Satisfaction', '98%', 'Client\nSatisfaction'),
        const SizedBox(width: 12),
        tile('Years of\nExperience', '8+', 'Years of\nExperience'),
      ])
    ]);
  }
}

class _CertificationsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget item(String title, String org, String year) => Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.military_tech, color: Color(0xFF2E7D32))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyle.semiBoldText(size: 14, color: Colors.black)),
            const SizedBox(height: 2),
            Text('$org • $year', style: AppTextStyle.regularText(size: 12, color: Colors.grey[700])),
          ])),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)), child: const Text('Verified')),
        ]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Certifications', style: AppTextStyle.semiBoldText(size: 16, color: Colors.black)),
        const SizedBox(height: 12),
        item('Certified Personal Trainer', 'NASM', '2020'),
        const SizedBox(height: 12),
        item('Sports Nutrition Specialist', 'ISSA', '2021'),
        const SizedBox(height: 12),
        item('Strength & Conditioning', 'NSCA', '2019'),
      ]),
    );
  }
}

class _SpecializationsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final specs = ['Strength Training', 'Weight Loss', 'Muscle Building', 'Nutrition Planning', 'HIIT', 'Rehabilitation'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Specializations', style: AppTextStyle.semiBoldText(size: 16, color: Colors.black)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: specs.map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)), child: Text(s))).toList()),
    ]);
  }
}


