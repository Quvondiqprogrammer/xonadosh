import 'package:flutter/material.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/domain/phone_countries.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';

Future<PhoneCountry?> showCountryPickerSheet(
  BuildContext context, {
  required PhoneCountry selected,
}) {
  return showModalBottomSheet<PhoneCountry>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _CountryPickerSheet(selected: selected),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected});

  final PhoneCountry selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<PhoneCountry> _filter(String lang) {
    final q = _search.text.trim().toLowerCase();
    final featured = <PhoneCountry>[];
    final rest = <PhoneCountry>[];
    for (final iso in PhoneCountry.featuredIsos) {
      featured.add(PhoneCountry.byIso(iso));
    }
    for (final c in PhoneCountry.all) {
      if (PhoneCountry.featuredIsos.contains(c.iso)) continue;
      rest.add(c);
    }
    rest.sort((a, b) => a.localizedName(lang).compareTo(b.localizedName(lang)));
    Iterable<PhoneCountry> all = [...featured, ...rest];
    if (q.isEmpty) return all.toList();
    return all.where((c) {
      return c.localizedName(lang).toLowerCase().contains(q) ||
          c.nameEn.toLowerCase().contains(q) ||
          c.iso.toLowerCase().contains(q) ||
          c.dial.contains(q) ||
          '+${c.dial}'.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _filter(lang);
    final h = MediaQuery.sizeOf(context).height * 0.72;

    return SizedBox(
      height: h,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              l10n.registerSelectCountry,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.registerSearchCountry,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final c = items[i];
                final selected = c.iso == widget.selected.iso;
                return ListTile(
                  leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                  title: Text(
                    c.localizedName(lang),
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    c.dial.isEmpty ? '+' : '+${c.dial}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? XonaDoshColors.emerald
                          : (isDark
                                ? const Color(0xFF94A3B8)
                                : XonaDoshColors.slate500),
                    ),
                  ),
                  selected: selected,
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
