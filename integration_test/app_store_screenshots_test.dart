import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xonadosh/main.dart' as app;

/// Triggers host `scripts/screenshot_server.py` via Mac bridge IP from Simulator.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const user = String.fromEnvironment('SHOT_USER', defaultValue: 'xdshot5122');
  const pass = String.fromEnvironment('SHOT_PASS', defaultValue: 'ShotTest123!');
  // Simulator → host: localhost works for some setups; bridge IP is more reliable.
  const host = String.fromEnvironment('SHOT_HOST', defaultValue: '127.0.0.1');
  const port = String.fromEnvironment('SHOT_PORT', defaultValue: '8765');

  Future<void> shot(String name) async {
    final uri = Uri.parse('http://$host:$port/shot?name=$name');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 15));
      final body = await res.transform(utf8.decoder).join();
      // ignore: avoid_print
      print('shot $name → $body');
      if (res.statusCode != 200) {
        fail('Host screenshot failed for $name: HTTP ${res.statusCode} $body');
      }
      final ok = body.contains('"ok": true') || body.contains('"ok":true');
      if (!ok) {
        fail('Host screenshot failed for $name: $body');
      }
    } finally {
      client.close(force: true);
    }
    // Give UI a beat after screenshot
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<void> settle(WidgetTester tester, [int pumps = 15]) async {
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<bool> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  testWidgets('App Store screenshots — all sections', (tester) async {
    // Probe host server first
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('http://$host:$port/health'));
      final res = await req.close().timeout(const Duration(seconds: 5));
      await res.drain<void>();
      client.close(force: true);
      if (res.statusCode != 200) {
        fail('Screenshot server not healthy on $host:$port');
      }
    } catch (e) {
      fail(
        'Cannot reach screenshot server at http://$host:$port — '
        'start scripts/screenshot_server.py first. ($e)',
      );
    }

    app.main();
    await tester.pump();
    await settle(tester, 10);

    final nav = find.byType(NavigationBar);
    final fields = find.byType(TextFormField);

    final hasNav = await waitFor(tester, nav, timeout: const Duration(seconds: 20));
    if (!hasNav) {
      final hasLogin = await waitFor(tester, fields, timeout: const Duration(seconds: 40));
      if (!hasLogin) fail('Neither login nor shell appeared');

      await shot('00_login');

      await tester.enterText(fields.at(0), user);
      await tester.enterText(fields.at(1), pass);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      Finder loginBtn = find.textContaining('Kirish');
      if (loginBtn.evaluate().isEmpty) loginBtn = find.textContaining('Login');
      if (loginBtn.evaluate().isEmpty) loginBtn = find.byType(ElevatedButton);
      if (loginBtn.evaluate().isEmpty) loginBtn = find.byType(FilledButton);
      expect(loginBtn, findsWidgets);
      await tester.tap(loginBtn.last);
      await settle(tester, 20);

      if (!await waitFor(tester, nav, timeout: const Duration(seconds: 60))) {
        fail('Login did not reach shell');
      }
    }

    await settle(tester, 20);
    await shot('01_uy_ijara');

    final mapIcon = find.byIcon(Icons.map_rounded);
    if (mapIcon.evaluate().isNotEmpty) {
      await tester.tap(mapIcon.first);
      await settle(tester, 25);
      await shot('02_xarita');
      if (find.byIcon(Icons.arrow_back_rounded).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      } else {
        await tester.pageBack();
      }
      await settle(tester, 12);
    }

    final listingTap = find.byType(InkWell);
    if (listingTap.evaluate().length > 2) {
      await tester.tap(listingTap.at(2));
      await settle(tester, 25);
      if (find.byType(NavigationBar).evaluate().isEmpty) {
        await shot('03_elon_detal');
        if (find.byIcon(Icons.arrow_back_rounded).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
        } else {
          await tester.pageBack();
        }
        await settle(tester, 12);
      }
    }

    Future<void> tapTab(String label) async {
      final t = find.text(label);
      expect(t, findsWidgets, reason: 'tab $label');
      await tester.tap(t.last);
      await settle(tester, 25);
    }

    await tapTab('Xonadosh Topish');
    await shot('04_xonadosh_topish');

    await tapTab('Kundalik & Bozorlik');
    await shot('05_navbatchilik');

    Future<void> openPill(String label, String file) async {
      final pill = find.text(label);
      if (pill.evaluate().isEmpty) {
        // ignore: avoid_print
        print('skip missing: $label');
        return;
      }
      await tester.ensureVisible(pill.first);
      await tester.tap(pill.first, warnIfMissed: false);
      await settle(tester, 22);
      await shot(file);
    }

    await openPill('Menyu', '06_taomnoma');
    await openPill('Bozorlik', '07_bozorlik');
    await openPill('Moliya & Qarz', '08_moliya_qarz');
    await openPill('Anonim Masalalar', '09_anonim_masalalar');
    await openPill('Obro‘ & Karma', '10_obro_karma');

    final settings = find.byIcon(Icons.settings_outlined);
    if (settings.evaluate().isNotEmpty) {
      await tester.tap(settings.first);
      await settle(tester, 18);
      await shot('11_sozlamalar');
    }

    // Notify server
    try {
      final c = HttpClient();
      final r = await c.getUrl(Uri.parse('http://$host:$port/done'));
      await (await r.close()).drain<void>();
      c.close(force: true);
    } catch (_) {}

    // ignore: avoid_print
    print('kIsWeb=$kIsWeb screenshots done');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
