import 'package:flutter/material.dart';
import 'package:ramala/template.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'About',
      children: [
        const Center(child: AppLogo(size: 72)),
        const Gap(AppSpace.lg),
        const SectionHeader('Tentang Ramala'),
        AppCard(
          child: Text(
            'Ramala adalah aplikasi pasar prediksi tempat kamu menebak hasil '
            'peristiwa nyata, mulai dari olahraga, teknologi, hingga ekonomi. '
            'Setiap pasar punya dua kemungkinan, YES atau NO. Harganya mencerminkan '
            'probabilitas yang dinilai oleh seluruh pengguna.\n\n'
            'Beli share di sisi yang kamu yakini, jual kapan saja saat harga '
            'bergerak, dan dapatkan 1 koin per share jika tebakanmu benar saat '
            'pasar diselesaikan. Harga bergerak otomatis mengikuti jumlah transaksi '
            'lewat mekanisme LMSR, sehingga selalu ada likuiditas.\n\n'
            'Ramala juga dilengkapi pantauan portofolio dan riwayat harga, '
            'konverter mata uang, kripto, dan zona waktu, pasar terdekat berbasis '
            'lokasi, asisten AI, mini game sensor, notifikasi, serta ledger '
            'blockchain yang dapat diverifikasi untuk menjaga transparansi '
            'setiap transaksi.',
            style: AppText.body,
          ),
        ),
        const Gap(AppSpace.xl),
        const SectionHeader('Saran & Kesan Mata Kuliah'),
        AppCard(
          child: Text(
            'Selama mengikuti mata kuliah ini, kami belajar keuntungan belajar otodidak, '
            'bagaimana cara kami bisa menelaah materi di waktu yang terbatas, '
            'cara mencari ilmu-ilmu yang lebih mendalam dari dasar mata kuliah itu sendiri, '
            'serta memberikan simulasi pengalaman yang dapat memberikan persiapan bagi '
            'kita di kehidupan mendatang.\n\n'
            'Harapan kami yaitu agar mata kuliah ini kedepannya dapat memberikan ketentuan '
            'penugasan yang lebih meringankan untuk diterapkan, dengan jangka waktu '
            'pengerjaan yang lebih murah hati.',
            style: AppText.body,
          ),
        ),
        const Gap(AppSpace.xl),
        Center(child: Text('Versi 1.0.0', style: AppText.caption)),
      ],
    );
  }
}
