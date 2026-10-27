// ============================================================================
// RAMALA DESIGN SYSTEM  (lib/template.dart)
// ============================================================================
// Konsep : "séance / kristal peramal". Gelap pekat + oranye labu + glow tipis.
//          Spooky lewat warna & glow, BUKAN ilustrasi. Tetap terbaca sebagai app trading.
// Tema   : SATU tema gelap permanen. Jangan buat mode terang / jangan baca platformBrightness.
//
// ATURAN PAKAI (wajib untuk semua halaman & prompt berikutnya)
// 1. Jangan hardcode warna/ukuran/font. Pakai AppColors, AppText, AppSpace, AppRadius, AppMotion.
// 2. Setiap halaman dibungkus AppScaffold. Konten scroll = `children`, konten khusus = `body`.
// 3. Warna bermakna: YES=hijau, NO=merah (hanya untuk arah/hasil pasar & PnL).
//    Oranye (primary) = aksi & merek. Amber (accent) = koin/uang & sorotan. Ungu (arcane) = info/grafik sekunder.
// 4. Satu AppButton primary per layar/panel. Aksi lain: secondary/ghost. Aksi merusak: danger.
// 5. Elevasi = border + glow oranye tipis (AppColors.glow). JANGAN pakai bayangan hitam bawaan.
// 6. Semua angka (harga, saldo, jumlah) pakai AppText.number / numberSm (tabular figures).
// 7. Judul/logo = Cinzel (AppText.display/title). Teks lain = Inter.
// 8. Loading = AppSkeleton (daftar/kartu) atau AppLoading (aksi). Kosong = EmptyState. Gagal = ErrorState (+retry).
// 9. Umpan balik singkat = AppToast. Konfirmasi aksi berisiko = AppConfirmDialog. Panel aksi = AppBottomSheet.
// 10. Input pengguna = AppTextField / AppSearchBar; validator diambil dari core/validators (jangan inline di halaman).
// 11. Status market selalu lewat MarketStatus.from(status, closeAt) ("closed" dihitung di client).
// 12. Teks UI berbahasa Indonesia, singkat. Radius & spasi hanya dari skala di bawah.
//
// IMPORT: import 'package:ramala/template.dart';
// PAKET: google_fonts, cached_network_image, fl_chart, intl.  ASET: assets/gambar/logo_ramala.png
// ============================================================================

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ============================================================================
// 1. TOKEN
// ============================================================================

/// Warna. Semua warna UI HARUS dari sini.
class AppColors {
  static const bg = Color(0xFF0B0710); // latar halaman (void)
  static const surface = Color(0xFF150E1C); // input, nav bar, sheet
  static const card = Color(0xFF1E1428); // kartu
  static const border = Color(0xFF2E2140); // garis tepi
  static const primary = Color(0xFFFF7A1A); // oranye labu: aksi & merek
  static const onPrimary = Color(0xFF1A0A00); // teks di atas primary
  static const accent = Color(0xFFFFC24A); // amber: koin, sorotan, peringatan
  static const arcane = Color(0xFF8B5CF6); // ungu: info, grafik sekunder
  static const yes = Color(0xFF7EE08A); // YES / untung
  static const no = Color(0xFFF0455A); // NO / rugi / error
  static const text = Color(0xFFF4EDE4); // teks utama
  static const textDim = Color(0xFFA89BB8); // teks sekunder
  static const textMuted = Color(0xFF6E617E); // placeholder, disabled

  /// Glow tipis pengganti elevasi.
  static List<BoxShadow> glow([Color c = primary]) => [
    BoxShadow(color: c.withValues(alpha: .28), blurRadius: 18),
  ];
}

/// Tipografi. Cinzel = judul/logo, Inter = isi. Angka selalu tabular.
class AppText {
  static const _tab = [FontFeature.tabularFigures()];
  static TextStyle _inter(
    double s,
    FontWeight w,
    Color c, {
    bool tab = false,
  }) => GoogleFonts.inter(
    fontSize: s,
    fontWeight: w,
    color: c,
    height: 1.35,
    fontFeatures: tab ? _tab : null,
  );
  static TextStyle _cinzel(double s, FontWeight w) => GoogleFonts.cinzel(
    fontSize: s,
    fontWeight: w,
    color: AppColors.text,
    letterSpacing: 1.2,
  );

  static TextStyle get display => _cinzel(28, FontWeight.w700); // logo, hero
  static TextStyle get title =>
      _cinzel(20, FontWeight.w700); // judul halaman/dialog
  static TextStyle get heading =>
      _inter(16, FontWeight.w600, AppColors.text); // judul kartu/seksi
  static TextStyle get body => _inter(14, FontWeight.w400, AppColors.text);
  static TextStyle get bodyDim =>
      _inter(14, FontWeight.w400, AppColors.textDim);
  static TextStyle get label =>
      _inter(13, FontWeight.w600, AppColors.text); // tombol, chip
  static TextStyle get caption =>
      _inter(12, FontWeight.w400, AppColors.textDim);
  static TextStyle get number =>
      _inter(22, FontWeight.w700, AppColors.text, tab: true);
  static TextStyle get numberSm =>
      _inter(14, FontWeight.w600, AppColors.text, tab: true);
}

/// Skala spasi.
class AppSpace {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
}

/// Skala radius sudut.
class AppRadius {
  static const sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, pill = 999.0;
}

/// Gerak: singkat dan halus.
class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const curve = Curves.easeOutCubic;
}

/// Pemformat tampilan (data mentah tetap angka di model).
class Fmt {
  static final _n = NumberFormat('#,##0.##');
  static String coin(num v) => _n.format(v);
  static String pct(double p) => '${(p * 100).round()}%';
}

/// Jarak vertikal ringkas: `const Gap(AppSpace.lg)`.
class Gap extends SizedBox {
  const Gap(double h, {super.key}) : super(height: h);
}

// ============================================================================
// 2. TEMA
// ============================================================================

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.accent,
        tertiary: AppColors.arcane,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        error: AppColors.no,
        outline: AppColors.border,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: .3),
        selectionHandleColor: AppColors.primary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        height: 66,
        indicatorColor: AppColors.primary.withValues(alpha: .18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppText.caption.copyWith(
            color: s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textDim,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textDim,
          ),
        ),
      ),
    );
  }
}

/// Dekorasi input seragam (dipakai AppTextField & AppSearchBar).
class AppInput {
  static InputDecoration decoration({
    String? label,
    String? hint,
    IconData? icon,
    Widget? suffix,
  }) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      suffixIcon: suffix,
      prefixIconColor: AppColors.textDim,
      suffixIconColor: AppColors.textDim,
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: AppText.bodyDim,
      hintStyle: AppText.bodyDim.copyWith(color: AppColors.textMuted),
      errorStyle: AppText.caption.copyWith(color: AppColors.no),
      counterStyle: AppText.caption,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: 14,
      ),
      border: b(AppColors.border),
      enabledBorder: b(AppColors.border),
      focusedBorder: b(AppColors.primary, 1.5),
      errorBorder: b(AppColors.no),
      focusedErrorBorder: b(AppColors.no, 1.5),
    );
  }
}

// ============================================================================
// 3. HALAMAN & NAVIGASI
// ============================================================================

/// Kerangka SEMUA halaman. `children` = daftar scroll (padding otomatis),
/// `body` = konten bebas. `onRefresh` mengaktifkan pull-to-refresh.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    this.children,
    this.body,
    this.onRefresh,
    this.bottomNav,
    this.fab,
  }) : assert(children != null || body != null);

  final String? title;
  final List<Widget>? actions;
  final List<Widget>? children;
  final Widget? body;
  final Future<void> Function()? onRefresh;
  final Widget? bottomNav;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    Widget content =
        body ??
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpace.lg),
          children: children!,
        );
    if (onRefresh != null && body == null) {
      content = RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: onRefresh!,
        child: content,
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1.1),
          radius: 1.3,
          colors: [Color(0xFF2A1238), AppColors.bg],
          stops: [0, .75],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: title == null
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                title: Text(title!, style: AppText.title),
                actions: actions,
              ),
        floatingActionButton: fab,
        bottomNavigationBar: bottomNav,
        body: SafeArea(
          top: title == null,
          bottom: bottomNav == null,
          child: content,
        ),
      ),
    );
  }
}

class AppNavItem {
  const AppNavItem(this.icon, this.label, [this.activeIcon]);
  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

/// Bottom navigation (gaya dari NavigationBarTheme). Maks 5 item.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.current,
    required this.onTap,
  });
  final List<AppNavItem> items;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: NavigationBar(
      selectedIndex: current,
      onDestinationSelected: onTap,
      destinations: [
        for (final i in items)
          NavigationDestination(
            icon: Icon(i.icon),
            selectedIcon: Icon(i.activeIcon ?? i.icon),
            label: i.label,
          ),
      ],
    ),
  );
}

/// Logo dari assets/gambar/logo_ramala.png (fallback ikon jika aset belum ada).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.showName = true});
  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/gambar/logo_ramala.png',
        height: size,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.auto_awesome, size: size * .6, color: AppColors.primary),
      ),
      if (showName) ...[
        const Gap(AppSpace.sm),
        Text(
          'RAMALA',
          style: AppText.display.copyWith(color: AppColors.primary),
        ),
      ],
    ],
  );
}

// ============================================================================
// 4. INPUT
// ============================================================================

enum AppButtonVariant { primary, secondary, ghost, danger }

/// Tombol. primary = aksi utama (ada glow). `loading` mengunci tombol.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });
  final String label;
  final VoidCallback? onPressed; // null = disabled
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading, expanded;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (
        AppColors.primary,
        AppColors.onPrimary,
        AppColors.primary,
      ),
      AppButtonVariant.secondary => (
        AppColors.card,
        AppColors.text,
        AppColors.border,
      ),
      AppButtonVariant.ghost => (
        Colors.transparent,
        AppColors.primary,
        Colors.transparent,
      ),
      AppButtonVariant.danger => (
        AppColors.no.withValues(alpha: .15),
        AppColors.no,
        AppColors.no,
      ),
    };
    final r = BorderRadius.circular(AppRadius.md);
    final content = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpace.sm),
              ],
              Text(label, style: AppText.label.copyWith(color: fg)),
            ],
          );
    return Opacity(
      opacity: enabled || loading ? 1 : .45,
      child: SizedBox(
        width: expanded ? double.infinity : null,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            boxShadow: variant == AppButtonVariant.primary && enabled
                ? AppColors.glow()
                : null,
          ),
          child: Material(
            color: bg,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: r,
              side: BorderSide(color: border),
            ),
            child: InkWell(
              onTap: enabled ? onPressed : null,
              child: Center(
                widthFactor: expanded ? null : 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Field teks. `password: true` menambah tombol lihat/sembunyi.
/// validator: ambil dari core/validators. formatters: batasi karakter yang boleh diketik.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.icon,
    this.validator,
    this.password = false,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.formatters,
    this.onChanged,
    this.action,
    this.enabled = true,
  });
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final bool password, enabled;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int maxLines;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final TextInputAction? action;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    enabled: widget.enabled,
    obscureText: widget.password && _hide,
    keyboardType: widget.keyboardType,
    maxLength: widget.maxLength,
    maxLines: widget.password ? 1 : widget.maxLines,
    inputFormatters: widget.formatters,
    onChanged: widget.onChanged,
    textInputAction: widget.action,
    validator: widget.validator,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    style: AppText.body,
    decoration: AppInput.decoration(
      label: widget.label,
      hint: widget.hint,
      icon: widget.icon,
      suffix: widget.password
          ? IconButton(
              icon: Icon(
                _hide
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _hide = !_hide),
            )
          : null,
    ),
  );
}

/// Pencarian dengan debounce 400 ms (hemat query). `onSearch` menerima teks yang sudah dirapikan.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.onSearch,
    this.hint = 'Cari market...',
  });
  final ValueChanged<String> onSearch;
  final String hint;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final _c = TextEditingController();
  Timer? _t;

  void _changed(String v) {
    setState(() {});
    _t?.cancel();
    _t = Timer(
      const Duration(milliseconds: 400),
      () => widget.onSearch(v.trim()),
    );
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _c,
    onChanged: _changed,
    maxLength: 60,
    style: AppText.body,
    textInputAction: TextInputAction.search,
    decoration: AppInput.decoration(
      hint: widget.hint,
      icon: Icons.search_rounded,
      suffix: _c.text.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _c.clear();
                _changed('');
              },
            ),
    ).copyWith(counterText: ''),
  );
}

/// Chip filter (kategori, urutan).
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: AppMotion.fast,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: .18)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppText.label.copyWith(
          color: selected ? AppColors.primary : AppColors.textDim,
        ),
      ),
    ),
  );
}

/// Tombol ikon persegi seukuran field input; `badge` = titik penanda pengaturan aktif.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: badge ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            color: badge ? AppColors.primary : AppColors.textDim,
          ),
        ),
        if (badge)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    ),
  );
}

/// Chip dua baris, scroll horizontal. Urutan: kiri-atas, kiri-bawah, kanan-atas, ...
/// (genap di baris atas, ganjil di baris bawah, tiap baris selebar isinya).
class AppChipRows extends StatelessWidget {
  const AppChipRows({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final top = <Widget>[], bottom = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      (i.isEven ? top : bottom).add(children[i]);
    }
    Widget row(List<Widget> r) => Row(
      children: [
        for (var i = 0; i < r.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpace.sm),
          r[i],
        ],
      ],
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(top),
          if (bottom.isNotEmpty) ...[const Gap(AppSpace.sm), row(bottom)],
        ],
      ),
    );
  }
}

class AppSegmentOption<T> {
  const AppSegmentOption(
    this.value,
    this.label, {
    this.color = AppColors.primary,
  });
  final T value;
  final String label;
  final Color color; // YES = AppColors.yes, NO = AppColors.no
}

/// Pilihan eksklusif 2-3 opsi (YES/NO, Beli/Jual).
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final List<AppSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < options.length; i++) ...[
        if (i > 0) const SizedBox(width: AppSpace.sm),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(options[i].value),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: options[i].value == value
                    ? options[i].color.withValues(alpha: .18)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: options[i].value == value
                      ? options[i].color
                      : AppColors.border,
                  width: options[i].value == value ? 1.5 : 1,
                ),
              ),
              child: Text(
                options[i].label,
                style: AppText.label.copyWith(
                  color: options[i].value == value
                      ? options[i].color
                      : AppColors.textDim,
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

/// Stepper jumlah (mis. share). Nilai selalu di-clamp ke min..max.
class AppAmountStepper extends StatelessWidget {
  const AppAmountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 1000,
    this.step = 1,
    this.label = 'Jumlah share',
  });
  final double value, min, max, step;
  final ValueChanged<double> onChanged;
  final String label;

  Widget _btn(IconData i, bool on, VoidCallback f) => IconButton(
    onPressed: on ? f : null,
    icon: Icon(i),
    style: IconButton.styleFrom(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.text,
      side: const BorderSide(color: AppColors.border),
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        _btn(
          Icons.remove,
          value > min,
          () => onChanged((value - step).clamp(min, max).toDouble()),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                value % 1 == 0
                    ? value.toStringAsFixed(0)
                    : value.toStringAsFixed(2),
                style: AppText.number,
              ),
              Text(label, style: AppText.caption),
            ],
          ),
        ),
        _btn(
          Icons.add,
          value < max,
          () => onChanged((value + step).clamp(min, max).toDouble()),
        ),
      ],
    ),
  );
}

// ============================================================================
// 5. TAMPILAN DATA
// ============================================================================

/// Kartu dasar. `glow` untuk penekanan (maks 1 per layar). `onTap` null = tidak interaktif.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.glow = false,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.borderColor,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool glow;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(AppRadius.lg);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: r,
        border: Border.all(
          color: borderColor ?? (glow ? AppColors.primary : AppColors.border),
        ),
        boxShadow: glow ? AppColors.glow() : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Label kecil berwarna (kategori, status).
class AppBadge extends StatelessWidget {
  const AppBadge(this.text, {super.key, this.color = AppColors.arcane});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Text(
      text,
      style: AppText.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Status market. Status "closed" TIDAK ada di database; dihitung dari close_at.
enum MarketStatus {
  open('Terbuka', AppColors.yes),
  closed('Ditutup', AppColors.accent),
  resolved('Selesai', AppColors.arcane),
  cancelled('Batal', AppColors.textDim);

  const MarketStatus(this.label, this.color);
  final String label;
  final Color color;

  static MarketStatus from(String status, DateTime closeAt) {
    if (status == 'resolved') return resolved;
    if (status == 'cancelled') return cancelled;
    return closeAt.isBefore(DateTime.now()) ? closed : open;
  }
}

/// Angka koin dengan ikon amber.
class CoinText extends StatelessWidget {
  const CoinText(this.value, {super.key, this.style});
  final num value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.toll_rounded, size: 16, color: AppColors.accent),
      const SizedBox(width: AppSpace.xs),
      Text(Fmt.coin(value), style: style ?? AppText.numberSm),
    ],
  );
}

/// Bar peluang YES vs NO. `yes` = 0..1 (price_yes dari database).
class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar({super.key, required this.yes});
  final double yes;

  @override
  Widget build(BuildContext context) {
    final p = yes.clamp(0.0, 1.0).toDouble();
    return Column(
      children: [
        Row(
          children: [
            Text(
              'YES ${Fmt.pct(p)}',
              style: AppText.numberSm.copyWith(color: AppColors.yes),
            ),
            const Spacer(),
            Text(
              'NO ${Fmt.pct(1 - p)}',
              style: AppText.numberSm.copyWith(color: AppColors.no),
            ),
          ],
        ),
        const Gap(6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.no.withValues(alpha: .35)),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: p),
                  duration: AppMotion.normal,
                  curve: AppMotion.curve,
                  builder: (_, v, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: v,
                    child: Container(color: AppColors.yes),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu market untuk daftar. Data diambil dari baris tabel `markets`.
class MarketCard extends StatelessWidget {
  const MarketCard({
    super.key,
    required this.title,
    required this.category,
    required this.priceYes,
    required this.volume,
    required this.status,
    required this.footer,
    this.imageUrl,
    this.onTap,
  });
  final String title, category, footer;
  final double priceYes, volume;
  final MarketStatus status;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppBadge(category.toUpperCase()),
            const SizedBox(width: AppSpace.sm),
            AppBadge(status.label, color: status.color),
            const Spacer(),
            CoinText(volume, style: AppText.caption),
          ],
        ),
        const Gap(AppSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const SizedBox(width: 52, height: 52),
                ),
              ),
              const SizedBox(width: AppSpace.md),
            ],
            Expanded(
              child: Text(
                title,
                style: AppText.heading,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const Gap(AppSpace.lg),
        ProbabilityBar(yes: priceYes),
        const Gap(AppSpace.md),
        Text(footer, style: AppText.caption),
      ],
    ),
  );
}

/// Angka ringkas (saldo, PnL). `delta` != null menampilkan panah hijau/merah.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.delta,
  });
  final String label, value;
  final IconData? icon;
  final double? delta;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpace.xs),
            ],
            Text(label, style: AppText.caption),
          ],
        ),
        const Gap(AppSpace.sm),
        Text(value, style: AppText.number),
        if (delta != null) ...[
          const Gap(AppSpace.xs),
          Text(
            '${delta! >= 0 ? '▲' : '▼'} ${Fmt.coin(delta!.abs())}',
            style: AppText.numberSm.copyWith(
              color: delta! >= 0 ? AppColors.yes : AppColors.no,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Foto profil bulat; jika tidak ada URL tampil huruf awal.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.url, this.radius = 24});
  final String name;
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = Center(
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: AppText.title.copyWith(
          fontSize: radius * .8,
          color: AppColors.primary,
        ),
      ),
    );
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card,
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: AppColors.glow(),
      ),
      child: ClipOval(
        child: url == null
            ? initial
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => initial,
              ),
      ),
    );
  }
}

/// Judul seksi + aksi opsional ("Lihat semua").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: Row(
      children: [
        Expanded(child: Text(title, style: AppText.heading)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: AppText.label.copyWith(color: AppColors.primary),
            ),
          ),
      ],
    ),
  );
}

/// Baris menu (profil, pengaturan). Letakkan di dalam AppCard(padding: EdgeInsets.zero).
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.danger = false,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? trailing; // menggantikan chevron bila diisi

  @override
  Widget build(BuildContext context) {
    final c = danger ? AppColors.no : AppColors.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            Icon(
              icon,
              color: danger ? AppColors.no : AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.body.copyWith(color: c)),
                  if (subtitle != null) Text(subtitle!, style: AppText.caption),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (!danger)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

/// Grafik harga YES (0..1). Semua grafik garis di app memakai gaya ini.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.data, this.height = 160});
  final List<double> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    const hide = AxisTitles(sideTitles: SideTitles(showTitles: false));
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 1,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: .25,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.border, strokeWidth: .6),
          ),
          titlesData: FlTitlesData(
            topTitles: hide,
            rightTitles: hide,
            bottomTitles: hide,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: .25,
                getTitlesWidget: (v, _) =>
                    Text(Fmt.pct(v), style: AppText.caption),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i]),
              ],
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: .3),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. UMPAN BALIK & STATE
// ============================================================================

/// Spinner untuk aksi/halaman singkat.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(AppSpace.xl),
      child: CircularProgressIndicator(),
    ),
  );
}

/// Placeholder berdenyut untuk daftar/kartu yang sedang dimuat.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
  });
  final double? width;
  final double height, radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.card, AppColors.border, _c.value),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

class _StateView extends StatelessWidget {
  const _StateView(
    this.icon,
    this.color,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  );
  final IconData icon;
  final Color color;
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: .12),
              border: Border.all(color: color.withValues(alpha: .5)),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const Gap(AppSpace.lg),
          Text(title, style: AppText.heading, textAlign: TextAlign.center),
          const Gap(AppSpace.xs),
          Text(message, style: AppText.bodyDim, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const Gap(AppSpace.lg),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.secondary,
              expanded: false,
            ),
          ],
        ],
      ),
    ),
  );
}

/// Data kosong (daftar belum ada isi).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.nightlight_round,
    this.actionLabel,
    this.onAction,
  });
  final String title, message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) =>
      _StateView(icon, AppColors.arcane, title, message, actionLabel, onAction);
}

/// Gagal memuat. Selalu sediakan retry.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _StateView(
    Icons.bolt_rounded,
    AppColors.no,
    'Terjadi masalah',
    message,
    'Coba lagi',
    onRetry,
  );
}

enum ToastType { success, error, info }

/// Notifikasi singkat di bawah layar.
class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    final (color, icon) = switch (type) {
      ToastType.success => (AppColors.yes, Icons.check_circle_rounded),
      ToastType.error => (AppColors.no, Icons.error_rounded),
      ToastType.info => (AppColors.accent, Icons.auto_awesome),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: color),
          ),
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpace.md),
              Expanded(child: Text(message, style: AppText.body)),
            ],
          ),
        ),
      );
  }
}

/// Konfirmasi aksi berisiko. Mengembalikan true jika dikonfirmasi.
class AppConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Ya',
    bool danger = false,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(title, style: AppText.title),
        content: Text(message, style: AppText.bodyDim),
        actions: [
          AppButton(
            label: 'Batal',
            variant: AppButtonVariant.ghost,
            expanded: false,
            onPressed: () => Navigator.pop(c, false),
          ),
          AppButton(
            label: confirmLabel,
            variant: danger
                ? AppButtonVariant.danger
                : AppButtonVariant.primary,
            expanded: false,
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );
    return r ?? false;
  }
}

/// Panel dari bawah (trading, filter, form singkat). Otomatis naik saat keyboard muncul.
class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (c) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const Gap(AppSpace.lg),
            Text(title, style: AppText.title),
            const Gap(AppSpace.lg),
            child,
          ],
        ),
      ),
    ),
  );
}
