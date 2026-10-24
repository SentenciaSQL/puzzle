import 'package:flutter/material.dart';

import '../audio/grove_audio.dart';
import '../game/levels.dart';
import '../l10n/strings.dart';
import '../paint/grove_art.dart';
import '../persist/save.dart';
import '../theme.dart';
import '../widgets/controls.dart';
import 'play_screen.dart';

class GroveShell extends StatefulWidget {
  const GroveShell({super.key, required this.save, required this.audio});
  final GroveSave save;
  final GroveAudio audio;

  @override
  State<GroveShell> createState() => _GroveShellState();
}

class _GroveShellState extends State<GroveShell> {
  String _page = 'splash';
  int _levelId = 1;
  String? _toast;

  @override
  void initState() {
    super.initState();
    widget.audio.syncMusic();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _page == 'splash') setState(() => _page = 'menu');
    });
  }

  void _go(String page) => setState(() => _page = page);

  void _play(int id) => setState(() {
    _levelId = id;
    _page = 'play';
  });

  void _ping(String message) {
    setState(() => _toast = message);
    final token = message;
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _toast == token) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.save,
      builder: (context, _) {
        final save = widget.save;
        return Scaffold(
          body: SkyBackdrop(
            motion: !save.reduced,
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: KeyedSubtree(
                    key: ValueKey(_page == 'play' ? 'play-$_levelId' : _page),
                    child: switch (_page) {
                      'splash' => _Splash(lang: save.lang),
                      'map' => _MapPage(
                        save: save,
                        onBack: () => _go('menu'),
                        onPlay: _play,
                      ),
                      'shop' => _ShopPage(
                        save: save,
                        audio: widget.audio,
                        onBack: () => _go('menu'),
                        onPing: _ping,
                      ),
                      'rewards' => _RewardsPage(
                        save: save,
                        audio: widget.audio,
                        onBack: () => _go('menu'),
                        onPing: _ping,
                      ),
                      'play' => PlayScreen(
                        levelId: _levelId,
                        save: save,
                        audio: widget.audio,
                        onMap: () => _go('map'),
                        onNext: () => _play(_levelId >= 24 ? 24 : _levelId + 1),
                      ),
                      _ => _MenuPage(
                        save: save,
                        audio: widget.audio,
                        onPlay: () => _play(save.unlocked.clamp(1, 24)),
                        onLevels: () => _go('map'),
                        onShop: () => _go('shop'),
                        onRewards: () => _go('rewards'),
                      ),
                    },
                  ),
                ),
                if (_toast != null)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 28,
                    child: Center(
                      child: GroveCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          _toast!,
                          textAlign: TextAlign.center,
                          style: body(15),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Emblem(size: 120),
          const SizedBox(height: 12),
          Text('Glimmer Grove', style: display(42)),
          const SizedBox(height: 8),
          Text(
            tr(lang, 'tagline'),
            style: body(16, color: creamDim, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _EmblemPainter()),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width * 0.48,
      Paint()..color = const Color(0x55301C58),
    );
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width * 0.46,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = gold,
    );
    paintGem(canvas, rect.deflate(size.width * 0.18), 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MenuPage extends StatelessWidget {
  const _MenuPage({
    required this.save,
    required this.audio,
    required this.onPlay,
    required this.onLevels,
    required this.onShop,
    required this.onRewards,
  });
  final GroveSave save;
  final GroveAudio audio;
  final VoidCallback onPlay;
  final VoidCallback onLevels;
  final VoidCallback onShop;
  final VoidCallback onRewards;

  @override
  Widget build(BuildContext context) {
    final lang = save.lang;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 800 && size.height >= 700;
    final compact = size.height < 560;
    final header = Row(
      children: [
        _AvatarButton(save: save),
        const Spacer(),
        CoinPill(coins: save.coins, onTap: onShop),
        const SizedBox(width: 8),
        IconDisc(
          draw: paintGear,
          tooltip: tr(lang, 'settings'),
          onPressed: () => _settings(context),
        ),
      ],
    );
    final hero = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Emblem(size: compact ? 64 : 132),
        SizedBox(height: compact ? 4 : 8),
        Text(
          'Glimmer',
          textAlign: TextAlign.center,
          style: display(compact ? 32 : (wide ? 64 : 52), color: gold),
        ),
        Text(
          'Grove',
          textAlign: TextAlign.center,
          style: display(compact ? 32 : (wide ? 64 : 52)),
        ),
        if (!compact) ...[
          const SizedBox(height: 6),
          Text(
            tr(lang, 'tagline'),
            textAlign: TextAlign.center,
            style: body(16, color: creamDim, weight: FontWeight.w600),
          ),
        ],
      ],
    );
    final actions = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GroveButton(label: tr(lang, 'play'), primary: true, onPressed: onPlay),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GroveButton(
                label: tr(lang, 'levels'),
                onPressed: onLevels,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GroveButton(label: tr(lang, 'shop'), onPressed: onShop),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GroveButton(
                label: tr(lang, 'rewards'),
                onPressed: onRewards,
              ),
            ),
          ],
        ),
        if (save.unlocked > 1) ...[
          const SizedBox(height: 12),
          GroveCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${tr(lang, 'level')} ${save.unlocked.clamp(1, 24)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: display(20, height: 1),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onPlay,
                  child: Text(
                    tr(lang, 'current'),
                    style: body(16, color: gold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
    final short = MediaQuery.sizeOf(context).height < 700 && !wide;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: wide
            ? Column(
                children: [
                  header,
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: Center(child: hero)),
                        const SizedBox(width: 24),
                        SizedBox(width: 360, child: actions),
                      ],
                    ),
                  ),
                ],
              )
            : short
            ? ListView(
                children: [
                  header,
                  const SizedBox(height: 18),
                  hero,
                  const SizedBox(height: 18),
                  actions,
                ],
              )
            : Column(
                children: [
                  header,
                  const Spacer(),
                  hero,
                  const Spacer(),
                  actions,
                ],
              ),
      ),
    );
  }

  Future<void> _settings(BuildContext context) {
    return showGroveDialog(
      context: context,
      builder: (context) => _SettingsCard(save: save, audio: audio),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.save});
  final GroveSave save;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('profile'),
      onTap: () => showGroveDialog(
        context: context,
        builder: (_) => _ProfileCard(save: save),
      ),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: line),
          color: const Color(0x88301C58),
        ),
        child: CustomPaint(painter: _GemPainter(save.avatar.clamp(0, 5))),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.save, required this.audio});
  final GroveSave save;
  final GroveAudio audio;

  @override
  Widget build(BuildContext context) {
    final lang = save.lang;
    return ListenableBuilder(
      listenable: save,
      builder: (context, _) {
        return GroveCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr(lang, 'settings'), style: display(30)),
              const SizedBox(height: 12),
              _toggle(tr(lang, 'sound'), save.sfx, () {
                save.sfx = !save.sfx;
                save.commit();
              }),
              _toggle(tr(lang, 'music'), save.music, () {
                save.music = !save.music;
                save.commit();
                audio.syncMusic();
              }),
              _toggle(tr(lang, 'motion'), save.reduced, () {
                save.reduced = !save.reduced;
                save.commit();
              }),
              const SizedBox(height: 8),
              Text(tr(lang, 'language'), style: body(14, color: creamDim)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: GroveButton(
                      label: 'English',
                      primary: lang == 'en',
                      onPressed: () => _lang('en'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GroveButton(
                      label: 'Español',
                      primary: lang == 'es',
                      onPressed: () => _lang('es'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GroveButton(
                label: tr(lang, 'how'),
                onPressed: () => _how(context, lang),
              ),
              const SizedBox(height: 8),
              GroveButton(
                label: tr(lang, 'reset'),
                onPressed: () async {
                  final ok = await showGroveDialog<bool>(
                    context: context,
                    builder: (context) => GroveCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tr(lang, 'resetAsk'),
                            textAlign: TextAlign.center,
                            style: body(16),
                          ),
                          const SizedBox(height: 12),
                          GroveButton(
                            label: tr(lang, 'confirm'),
                            primary: true,
                            onPressed: () => Navigator.pop(context, true),
                          ),
                          const SizedBox(height: 8),
                          GroveButton(
                            label: tr(lang, 'cancel'),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (ok == true) save.reset();
                },
              ),
              const SizedBox(height: 8),
              GroveButton(
                label: tr(lang, 'close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _lang(String code) {
    save.lang = code;
    save.commit();
  }

  void _how(BuildContext context, String lang) {
    showGroveDialog(
      context: context,
      builder: (context) => GroveCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr(lang, 'how'), style: display(28)),
            const SizedBox(height: 8),
            Text(tr(lang, 'how1'), style: body(15, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(tr(lang, 'how2'), style: body(15, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(tr(lang, 'how3'), style: body(15, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(tr(lang, 'iceTip'), style: body(15, color: gold)),
            const SizedBox(height: 12),
            GroveButton(
              label: tr(lang, 'close'),
              primary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0x332A1754),
            border: Border.all(color: line),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: body(16))),
              Container(
                width: 46,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: value ? gold : const Color(0xFF3A2A58),
                ),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                padding: const EdgeInsets.all(3),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: cream,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({required this.save});
  final GroveSave save;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  late final TextEditingController _name = TextEditingController(
    text: widget.save.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.save.lang;
    return GroveCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr(lang, 'profile'), style: display(28)),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            style: body(16),
            decoration: InputDecoration(
              hintText: tr(lang, 'yourName'),
              hintStyle: body(16, color: creamDim),
              filled: true,
              fillColor: const Color(0x552A1754),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: line),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(tr(lang, 'avatar'), style: body(13, color: creamDim)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < 6; i++)
                GestureDetector(
                  onTap: () => setState(() => widget.save.avatar = i),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.save.avatar == i ? gold : line,
                        width: widget.save.avatar == i ? 3 : 1,
                      ),
                    ),
                    child: CustomPaint(painter: _GemPainter(i)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GroveButton(
            label: tr(lang, 'saveName'),
            primary: true,
            onPressed: () {
              widget.save.name = _name.text.trim();
              widget.save.commit();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _GemPainter extends CustomPainter {
  _GemPainter(this.gem);
  final int gem;
  @override
  void paint(Canvas canvas, Size size) =>
      paintGem(canvas, Offset.zero & size, gem);
  @override
  bool shouldRepaint(covariant _GemPainter oldDelegate) =>
      oldDelegate.gem != gem;
}

class _MapPage extends StatelessWidget {
  const _MapPage({
    required this.save,
    required this.onBack,
    required this.onPlay,
  });
  final GroveSave save;
  final VoidCallback onBack;
  final void Function(int id) onPlay;

  @override
  Widget build(BuildContext context) {
    final lang = save.lang;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
            child: Row(
              children: [
                IconDisc(
                  draw: paintBack,
                  tooltip: tr(lang, 'back'),
                  onPressed: onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(lang, 'levels'),
                    style: display(28, height: 1),
                  ),
                ),
                CoinPill(coins: save.coins),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                for (final chapter in chapters) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.name(lang),
                          style: display(24, color: gold),
                        ),
                        Text(
                          chapter.blurb(lang),
                          style: body(
                            14,
                            color: creamDim,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final level in groveLevels.where(
                    (level) => level.chapter == chapter.id,
                  ))
                    _LevelNode(level: level, save: save, onPlay: onPlay),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.save,
    required this.onPlay,
  });
  final LevelDef level;
  final GroveSave save;
  final void Function(int id) onPlay;

  @override
  Widget build(BuildContext context) {
    final locked = level.id > save.unlocked;
    final progress = save.levels[level.id];
    final align = level.id.isEven
        ? Alignment.centerLeft
        : Alignment.centerRight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Align(
        alignment: align,
        child: GestureDetector(
          onTap: locked ? null : () => onPlay(level.id),
          child: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: locked
                      ? const LinearGradient(
                          colors: [Color(0xFF3A3158), Color(0xFF241838)],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFE7A0), gold, goldDeep],
                        ),
                  border: Border.all(
                    color: locked ? line : const Color(0xFFFFF6D2),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44000000),
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: locked
                    ? const GroveMark(paintLock, size: 28)
                    : Text(
                        '${level.id}',
                        style: display(26, color: goldInk, height: 1),
                      ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    GroveMark(
                      (canvas, size) => paintStar(
                        canvas,
                        size,
                        lit: (progress?.stars ?? 0) > i,
                      ),
                      size: 16,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopPage extends StatelessWidget {
  const _ShopPage({
    required this.save,
    required this.audio,
    required this.onBack,
    required this.onPing,
  });
  final GroveSave save;
  final GroveAudio audio;
  final VoidCallback onBack;
  final void Function(String message) onPing;

  @override
  Widget build(BuildContext context) {
    final lang = save.lang;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
            child: Row(
              children: [
                IconDisc(
                  draw: paintBack,
                  tooltip: tr(lang, 'back'),
                  onPressed: onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tr(lang, 'shop'), style: display(28, height: 1)),
                ),
                CoinPill(coins: save.coins),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              crossAxisCount: MediaQuery.sizeOf(context).width >= 800 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
              children: [
                for (final product in products)
                  _ProductCard(
                    product: product,
                    save: save,
                    onBuy: () {
                      if (!save.spend(product.cost)) {
                        onPing(tr(lang, 'need'));
                        return;
                      }
                      save.grant(product.grant);
                      audio.play('coin');
                      onPing(tr(lang, 'bought'));
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.save,
    required this.onBuy,
  });
  final Product product;
  final GroveSave save;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final lang = save.lang;
    final title = tr(lang, product.id);
    final desc = tr(lang, '${product.id}Desc');
    void Function(Canvas, Size) art = paintHammer;
    if (product.id == 'shuffle') art = paintStir;
    if (product.id == 'extra') art = paintPlus;
    if (product.id == 'basket') art = paintGift;
    final broke = save.coins < product.cost;
    return GroveCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Center(child: GroveMark(art, size: 64))),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: display(18, height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: body(12, color: creamDim, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GroveButton(
            label: broke ? tr(lang, 'need') : '${product.cost}',
            enabled: !broke,
            primary: !broke,
            onPressed: broke ? null : onBuy,
          ),
        ],
      ),
    );
  }
}

class _RewardsPage extends StatelessWidget {
  const _RewardsPage({
    required this.save,
    required this.audio,
    required this.onBack,
    required this.onPing,
  });
  final GroveSave save;
  final GroveAudio audio;
  final VoidCallback onBack;
  final void Function(String message) onPing;

  @override
  Widget build(BuildContext context) {
    final lang = save.lang;
    final ready = save.dailyReady;
    final stars = save.totalStars;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              IconDisc(
                draw: paintBack,
                tooltip: tr(lang, 'back'),
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr(lang, 'rewards'), style: display(28, height: 1)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GroveCard(
            child: Column(
              children: [
                const GroveMark(paintGift, size: 84),
                const SizedBox(height: 8),
                Text(tr(lang, 'daily'), style: display(28)),
                const SizedBox(height: 4),
                Text(
                  ready
                      ? '100 + 1 ${tr(lang, 'hammer')}'
                      : tr(lang, 'tomorrow'),
                  textAlign: TextAlign.center,
                  style: body(15, color: creamDim, weight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                GroveButton(
                  label: ready ? tr(lang, 'claim') : tr(lang, 'claimed'),
                  primary: ready,
                  enabled: ready,
                  onPressed: ready
                      ? () {
                          save.claimDaily();
                          audio.play('coin');
                          onPing(tr(lang, 'giftGot'));
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GroveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(lang, 'progress'), style: display(24)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const GroveMark(paintStar, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '$stars / ${groveLevels.length * 3}',
                      style: display(22, height: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: stars / (groveLevels.length * 3),
                    minHeight: 12,
                    backgroundColor: const Color(0xFF2A1754),
                    color: gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${tr(lang, 'level')} ${save.unlocked.clamp(1, 24)}',
                  style: body(14, color: creamDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
