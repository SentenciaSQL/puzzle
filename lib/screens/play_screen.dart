import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../audio/grove_audio.dart';
import '../game/levels.dart';
import '../game/session.dart';
import '../l10n/strings.dart';
import '../paint/grove_art.dart';
import '../persist/save.dart';
import '../theme.dart';
import '../widgets/controls.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.levelId,
    required this.save,
    required this.audio,
    required this.onMap,
    required this.onNext,
  });

  final int levelId;
  final GroveSave save;
  final GroveAudio audio;
  final VoidCallback onMap;
  final VoidCallback onNext;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  late GroveSession session;
  late final Ticker _ticker;
  (int, int)? _dragFrom;
  bool _dragged = false;
  _OverlayKind _overlay = _OverlayKind.none;
  int _reward = 0;
  int _stars = 0;

  @override
  void initState() {
    super.initState();
    _openSession();
    _ticker = createTicker(_onTick)..start();
    session.load();
    if (!widget.save.tutorial && widget.levelId == 1) {
      _overlay = _OverlayKind.intro;
    }
  }

  void _onTick(Duration elapsed) => session.tick(elapsed);

  void _openSession() {
    final level = groveLevel(widget.levelId);
    session = GroveSession(
      level: level,
      reduced: widget.save.reduced,
      onSound: widget.audio.play,
      onConsume: widget.save.consume,
      onWin: (score, stars, _) {
        _reward = widget.save.finishLevel(level.id, stars, score);
        _stars = stars;
        _overlay = _OverlayKind.win;
        if (mounted) setState(() {});
      },
      onLose: (_) {
        _overlay = _OverlayKind.lose;
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    session.dispose();
    super.dispose();
  }

  LevelDef get level => session.level;
  String get lang => widget.save.lang;

  void _retry() {
    final previous = session;
    _openSession();
    previous.dispose();
    if (!_ticker.isActive) _ticker.start();
    session.load();
    setState(() => _overlay = _OverlayKind.none);
  }

  @override
  Widget build(BuildContext context) {
    final chapter = chapters[level.chapter];
    return ListenableBuilder(
      listenable: Listenable.merge([session, widget.save]),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final short =
                constraints.maxHeight < 520 &&
                constraints.maxWidth > constraints.maxHeight;
            return Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: wide
                        ? _wide(chapter, constraints)
                        : short
                        ? _landscape(chapter, constraints)
                        : _phone(chapter, constraints),
                  ),
                ),
                if (_overlay != _OverlayKind.none) _overlayCard(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _phone(Chapter chapter, BoxConstraints constraints) {
    return Column(
      children: [
        _top(chapter),
        const SizedBox(height: 8),
        _goals(),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, inner) =>
                Center(child: _board(inner.maxWidth, inner.maxHeight, false)),
          ),
        ),
        const SizedBox(height: 8),
        _moves(),
        const SizedBox(height: 8),
        _boosters(),
      ],
    );
  }

  Widget _landscape(Chapter chapter, BoxConstraints constraints) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: LayoutBuilder(
            builder: (context, inner) =>
                Center(child: _board(inner.maxWidth, inner.maxHeight, false)),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: math.min(210, constraints.maxWidth * 0.34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _top(chapter, compact: true),
              const SizedBox(height: 8),
              _goals(stacked: true),
              const Spacer(),
              _moves(),
              const SizedBox(height: 8),
              _boosters(narrow: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _wide(Chapter chapter, BoxConstraints constraints) {
    return Row(
      children: [
        SizedBox(
          width: 230,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _top(chapter),
              const SizedBox(height: 12),
              Text(tr(lang, 'goals'), style: body(13, color: creamDim)),
              const SizedBox(height: 8),
              _goals(stacked: true),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, inner) => Center(
              child: _board(
                math.min(560, inner.maxWidth),
                inner.maxHeight,
                true,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 230,
          child: Column(
            children: [
              Align(alignment: Alignment.centerRight, child: _pauseButton()),
              const Spacer(),
              _moves(),
              const SizedBox(height: 16),
              _boosters(narrow: true),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _top(Chapter chapter, {bool compact = false}) {
    return Row(
      children: [
        IconDisc(
          draw: paintBack,
          tooltip: tr(lang, 'map'),
          onPressed: widget.onMap,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chapter.name(lang).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(11, color: gold),
              ),
              Text(
                '${tr(lang, 'level')} ${level.id}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: display(compact ? 20 : 26, height: 1),
              ),
            ],
          ),
        ),
        if (!compact) _pauseButton(),
      ],
    );
  }

  Widget _pauseButton() {
    return IconDisc(
      draw: (canvas, size) {
        final paint = Paint()..color = cream;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.22,
              size.height * 0.2,
              size.width * 0.18,
              size.height * 0.6,
            ),
            const Radius.circular(3),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.58,
              size.height * 0.2,
              size.width * 0.18,
              size.height * 0.6,
            ),
            const Radius.circular(3),
          ),
          paint,
        );
      },
      tooltip: tr(lang, 'pause'),
      onPressed: () {
        if (session.over != null) return;
        _ticker.stop();
        setState(() => _overlay = _OverlayKind.pause);
      },
    );
  }

  Widget _goals({bool stacked = false}) {
    final chips = <Widget>[];
    for (var i = 0; i < level.goals.length; i++) {
      final goal = level.goals[i];
      final done = session.goalFlags.length > i && session.goalFlags[i];
      final String label;
      Widget? mark;
      if (goal.type == 'score') {
        label = '${session.score.clamp(0, goal.target)}/${goal.target}';
        mark = Text(tr(lang, 'scoreGoal'), style: body(11, color: goldInk));
      } else {
        final have = session.collected[goal.gem] ?? 0;
        label = '${have.clamp(0, goal.target)}/${goal.target}';
        mark = SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(painter: _GemPainter(goal.gem ?? 0)),
        );
      }
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: done ? const Color(0xFFFFE7A8) : const Color(0xCC2A1754),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: done ? gold : line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark,
              const SizedBox(width: 6),
              Text(label, style: body(14, color: done ? goldInk : cream)),
            ],
          ),
        ),
      );
    }
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final chip in chips)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: chip),
        ],
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final chip in chips)
              Padding(padding: const EdgeInsets.only(right: 8), child: chip),
          ],
        ),
      ),
    );
  }

  Widget _moves() {
    return Column(
      children: [
        Text('${session.moves}', style: display(40, color: gold, height: 1)),
        Text(tr(lang, 'moves').toUpperCase(), style: body(11, color: creamDim)),
        const SizedBox(height: 4),
        Text('${session.shownScore.round()}', style: display(18, height: 1)),
      ],
    );
  }

  Widget _boosters({bool narrow = false}) {
    Widget item(
      String id,
      int count,
      void Function(Canvas, Size) draw,
      VoidCallback onTap,
    ) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: narrow ? 74 : 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: session.aim == id
                    ? const Color(0xCCFFE7A8)
                    : const Color(0x88301C58),
                border: Border.all(color: session.aim == id ? gold : line),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GroveMark(draw, size: 26),
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: body(12, color: session.aim == id ? goldInk : cream),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (session.aim == 'hammer')
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              tr(lang, 'aimHammer'),
              textAlign: TextAlign.center,
              style: body(13, color: gold),
            ),
          ),
        Row(
          children: [
            item('hammer', widget.save.hammer, paintHammer, () {
              if (widget.save.hammer <= 0) return;
              if (session.aim == 'hammer') {
                session.cancelAim();
              } else {
                session.arm('hammer');
              }
            }),
            item('shuffle', widget.save.shuffleBooster, paintStir, () {
              if (widget.save.shuffleBooster <= 0 || session.busy) return;
              session.arm('shuffle');
            }),
            item('extra', widget.save.extra, paintPlus, () {
              if (widget.save.extra <= 0 || session.over != null) return;
              widget.save.consume('extra');
              session.grantMoves(5);
              widget.audio.play('coin');
            }),
          ],
        ),
      ],
    );
  }

  Widget _board(double maxWidth, double maxHeight, bool wide) {
    final metrics = BoardMetrics.fit(
      rows: level.rows,
      cols: level.cols,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      wide: wide,
    );
    return SizedBox(
      width: metrics.width,
      height: metrics.height,
      child: GestureDetector(
        onTapUp: (details) {
          if (_overlay != _OverlayKind.none) return;
          final cell = metrics.cellAt(details.localPosition);
          if (cell != null) session.select(cell.$1, cell.$2);
        },
        onPanStart: (details) {
          _dragged = false;
          _dragFrom = metrics.cellAt(details.localPosition);
        },
        onPanUpdate: (details) {
          final from = _dragFrom;
          if (from == null || _dragged || _overlay != _OverlayKind.none) return;
          final cell = metrics.cellAt(details.localPosition);
          if (cell == null) return;
          final adjacent =
              (from.$1 - cell.$1).abs() + (from.$2 - cell.$2).abs() == 1;
          if (!adjacent) return;
          _dragged = true;
          session.dragSwap(from.$1, from.$2, cell.$1, cell.$2);
        },
        child: CustomPaint(
          painter: _BoardPainter(session, lang),
          size: metrics.size,
        ),
      ),
    );
  }

  Widget _overlayCard() {
    final title = switch (_overlay) {
      _OverlayKind.win => tr(lang, 'winTitle'),
      _OverlayKind.lose => tr(lang, 'loseTitle'),
      _OverlayKind.pause => tr(lang, 'paused'),
      _OverlayKind.intro => tr(lang, 'how'),
      _OverlayKind.none => '',
    };
    final sub = switch (_overlay) {
      _OverlayKind.win => tr(lang, 'winSub'),
      _OverlayKind.lose => tr(lang, 'loseSub'),
      _OverlayKind.intro => tr(lang, 'tutorial'),
      _ => '',
    };
    return ColoredBox(
      color: const Color(0xC8140A28),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GroveCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: display(
                        32,
                        color: _overlay == _OverlayKind.lose ? creamDim : gold,
                      ),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        sub,
                        textAlign: TextAlign.center,
                        style: body(15, color: cream, weight: FontWeight.w600),
                      ),
                    ],
                    if (_overlay == _OverlayKind.win) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: GroveMark(
                                (canvas, size) =>
                                    paintStar(canvas, size, lit: i < _stars),
                                size: 36,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const GroveMark(paintCoin, size: 22),
                          const SizedBox(width: 6),
                          Text('+$_reward', style: display(22, height: 1)),
                        ],
                      ),
                    ],
                    if (_overlay == _OverlayKind.intro) ...[
                      const SizedBox(height: 10),
                      Text(
                        tr(lang, 'how2'),
                        textAlign: TextAlign.center,
                        style: body(
                          14,
                          color: creamDim,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr(lang, 'iceTip'),
                        textAlign: TextAlign.center,
                        style: body(
                          14,
                          color: creamDim,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_overlay == _OverlayKind.pause)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${tr(lang, 'score')} ${session.score}',
                          style: body(14, color: creamDim),
                        ),
                      ),
                    if (session.aim == 'hammer' &&
                        _overlay == _OverlayKind.none)
                      const SizedBox.shrink(),
                    const SizedBox(height: 16),
                    ..._overlayActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _overlayActions() {
    if (_overlay == _OverlayKind.intro) {
      return [
        GroveButton(
          label: tr(lang, 'start'),
          primary: true,
          onPressed: () {
            widget.save.tutorial = true;
            widget.save.commit();
            setState(() => _overlay = _OverlayKind.none);
          },
        ),
      ];
    }
    if (_overlay == _OverlayKind.pause) {
      return [
        GroveButton(
          label: tr(lang, 'resume'),
          primary: true,
          onPressed: () {
            _ticker.start();
            setState(() => _overlay = _OverlayKind.none);
          },
        ),
        const SizedBox(height: 8),
        GroveButton(label: tr(lang, 'retry'), onPressed: _retry),
        const SizedBox(height: 8),
        GroveButton(label: tr(lang, 'map'), onPressed: widget.onMap),
      ];
    }
    if (_overlay == _OverlayKind.win) {
      final last = level.id >= 24;
      return [
        GroveButton(
          label: last ? tr(lang, 'done') : tr(lang, 'next'),
          primary: true,
          onPressed: last ? widget.onMap : widget.onNext,
        ),
        const SizedBox(height: 8),
        GroveButton(label: tr(lang, 'map'), onPressed: widget.onMap),
      ];
    }
    final canToken = widget.save.extra > 0;
    final canBuy = widget.save.coins >= 160;
    return [
      GroveButton(label: tr(lang, 'retry'), primary: true, onPressed: _retry),
      const SizedBox(height: 8),
      GroveButton(
        label: canToken ? tr(lang, 'continue') : tr(lang, 'buyMoves'),
        enabled: canToken || canBuy,
        onPressed: () {
          if (canToken) {
            widget.save.consume('extra');
          } else if (!widget.save.spend(160)) {
            return;
          }
          session.grantMoves(5);
          widget.audio.play('coin');
          setState(() => _overlay = _OverlayKind.none);
        },
      ),
      const SizedBox(height: 8),
      GroveButton(label: tr(lang, 'map'), onPressed: widget.onMap),
    ];
  }
}

enum _OverlayKind { none, intro, pause, win, lose }

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

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.session, this.lang);
  final GroveSession session;
  final String lang;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = size.width * 0.42 / (session.level.cols + 0.84);
    final cell = (size.width - pad * 2) / session.level.cols;
    final fitted = BoardMetrics(
      rows: session.level.rows,
      cols: session.level.cols,
      cell: cell,
      pad: pad,
      origin: Offset(pad, pad),
    );
    paintWood(
      canvas,
      fitted,
      time: session.clock,
      selected: session.selected,
      shake: session.shake,
      hint: session.hint == null
          ? null
          : HintPulse(
              (session.hint!.r1, session.hint!.c1),
              (session.hint!.r2, session.hint!.c2),
            ),
    );
    final pieces = session.pieces.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final piece in pieces) {
      final rect = fitted.cellRect(piece.r, piece.c).deflate(cell * 0.04);
      paintGem(
        canvas,
        rect,
        piece.gem,
        special: piece.special,
        frost: piece.frost,
        alpha: piece.alpha,
        scale: piece.scale,
      );
    }
    for (final spark in session.sparks) {
      final center = fitted.cellRect(spark.r - 0.5, spark.c - 0.5).center;
      final fade = (1 - spark.age / spark.life).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        cell * spark.size,
        Paint()
          ..color = gemPalette[spark.gem.clamp(0, 5)].withValues(alpha: fade),
      );
    }
    for (final ring in session.rings) {
      final rect = fitted.cellRect(ring.r, ring.c);
      final t = (ring.age / ring.life).clamp(0.0, 1.0);
      canvas.drawCircle(
        rect.center,
        cell * (0.4 + t * (ring.wide ? 2.4 : 1.4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: (1 - t) * 0.7),
      );
    }
    for (final floater in session.floaters) {
      final anchor = fitted.cellRect(floater.r, floater.c).center;
      final rise = floater.age / 14;
      final painter = TextPainter(
        text: TextSpan(
          text: floater.text,
          style: display(18, color: cream, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, anchor - Offset(painter.width / 2, 18 + rise));
    }
    if (session.comboLabel != null && session.comboAge < 900) {
      final label = tr(lang, session.comboLabel!);
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: display(28, color: gold),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      final fade = session.comboAge < 700
          ? 1.0
          : 1 - (session.comboAge - 700) / 200;
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: fade.clamp(0, 1)),
      );
      painter.paint(
        canvas,
        Offset((size.width - painter.width) / 2, size.height * 0.08),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
