/**
 * XonaDosh Web SPA — parity with Flutter mobile UX
 * Globals: Api, I18n, Locations, L (Leaflet)
 */
(() => {
  'use strict';

  const PROFILE_CACHE = 'xd_web_profile_cache';
  const AMENITIES = [
    'Wi-Fi', 'Kir yuvish mashinasi', 'Muzlatgich', 'Konditsioner', 'Gaz plita',
    'Mebel', 'Issiq suv', 'Televizor', 'Balkon', 'Domofon', 'Avtoturargoh',
    'Avtonom isitish (Kotyol)', 'Mikroto‘lqinli pech', 'Lift', 'Qo‘riqlash / Kamera', 'Basseyn',
  ];
  const DAYS_UZ = ['dushanba', 'seshanba', 'chorshanba', 'payshanba', 'juma', 'shanba', 'yakshanba'];
  const DAY_LABEL = {
    dushanba: 'Dushanba', seshanba: 'Seshanba', chorshanba: 'Chorshanba',
    payshanba: 'Payshanba', juma: 'Juma', shanba: 'Shanba', yakshanba: 'Yakshanba',
  };
  const MEAL_ORDER = ['breakfast', 'lunch', 'dinner'];
  const TASHKENT = { lat: 41.311081, lng: 69.240562 };
  const TYPE_META = {
    rent: { cls: 'type-rent', icon: '🏠' },
    roommate_wanted: { cls: 'type-roommate', icon: '👥' },
    sell: { cls: 'type-sell', icon: '🏷️' },
    buy: { cls: 'type-buy', icon: '🛒' },
  };

  const state = {
    route: 'housing',
    params: {},
    unis: [],
    listings: [],
    selectedUniId: '',
    listingFilters: {
      q: '', type: 'all', city: '', district: '', gender: 'any',
    },
    matchFilters: { gender: 'any' },
    myProfile: null,
    colivingSub: 'chores',
    mapInstance: null,
    groceryRoommates: 4,
    financeFilter: 'all',

    createPhotos: [],
  };

  /* ─── helpers ─────────────────────────────────────────── */
  function $(sel, root) { return (root || document).querySelector(sel); }
  function $$(sel, root) { return Array.from((root || document).querySelectorAll(sel)); }

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  function money(n, currency) {
    const v = Number(n) || 0;
    const sym = (Locations.currencySymbols && Locations.currencySymbols[currency || 'UZS']) || 'so‘m';
    try {
      return new Intl.NumberFormat('uz-UZ').format(Math.round(v)) + ' ' + sym;
    } catch {
      return Math.round(v).toLocaleString() + ' ' + sym;
    }
  }

  function periodLabel(p) {
    const map = {
      month: I18n.t('periodMonth'), day: I18n.t('periodDay'),
      year: I18n.t('periodYear'), total: I18n.t('periodTotal'),
    };
    return map[p] || I18n.t('periodMonth');
  }

  function toast(msg, ms) {
    const root = $('#toastRoot');
    if (!root) return;
    root.innerHTML = `<div class="toast">${esc(msg)}</div>`;
    clearTimeout(toast._t);
    toast._t = setTimeout(() => { root.innerHTML = ''; }, ms || 2800);
  }

  function spinner(msg) {
    return `<div class="empty"><div class="spinner"></div><p>${esc(msg || I18n.t('loading'))}</p></div>`;
  }

  function emptyState(text, ico, extraHtml) {
    return `<div class="empty"><div class="ico">${ico || '·'}</div><p>${esc(text)}</p>${extraHtml || ''}</div>`;
  }

  function errBox(msg, retryId) {
    return `<div class="empty"><p class="err">${esc(msg || 'Xato')}</p>
      ${retryId ? `<button type="button" class="btn btn-ghost btn-sm" id="${esc(retryId)}">${esc(I18n.t('retry'))}</button>` : ''}</div>`;
  }

  function telHref(phone) {
    const d = String(phone || '').replace(/[^\d+]/g, '');
    return d ? `tel:${d}` : '#';
  }

  function tgHref(handle) {
    let h = String(handle || '').trim().replace(/^@/, '');
    if (!h) return '#';
    if (/^https?:\/\//i.test(h)) return h;
    return 'https://t.me/' + encodeURIComponent(h);
  }

  function typeLabel(t) {
    const map = {
      rent: I18n.t('rent'), roommate_wanted: I18n.t('roommate'),
      sell: I18n.t('sell'), buy: I18n.t('buy'),
    };
    return map[t] || t || '';
  }

  function typeClass(t) {
    return (TYPE_META[t] && TYPE_META[t].cls) || 'type-rent';
  }

  function typeIcon(t) {
    return (TYPE_META[t] && TYPE_META[t].icon) || '🏠';
  }

  function genderLabel(g) {
    if (g === 'boys' || g === 'male') return I18n.t('boys');
    if (g === 'girls' || g === 'female') return I18n.t('girls');
    if (g === 'family') return I18n.t('family');
    return I18n.t('any');
  }

  function scoreTier(score) {
    const s = Number(score) || 0;
    if (s >= 90) return { cls: 'score-ideal', color: 'var(--em2)' };
    if (s >= 75) return { cls: 'score-good', color: 'var(--purple)' };
    return { cls: 'score-ok', color: 'var(--amber)' };
  }

  /* Habit label helpers (uz/ru/en via I18n) */
  function habitSleep(v) {
    if (v === 'early_bird') return I18n.t('habitEarlyBird');
    if (v === 'night_owl') return I18n.t('habitNightOwl');
    return I18n.t('habitFlexible');
  }
  function habitClean(v) {
    if (v === 'strict') return I18n.t('habitStrict');
    if (v === 'relaxed') return I18n.t('habitRelaxed');
    return I18n.t('habitModerate');
  }
  function habitStudy(v) {
    if (v === 'silent') return I18n.t('habitSilent');
    if (v === 'music') return I18n.t('habitMusic');
    if (v === 'group') return I18n.t('habitGroup');
    return I18n.t('habitFlexible');
  }
  function habitCook(v) {
    if (v === 'rotates') return I18n.t('habitRotates');
    if (v === 'often' || v === 'cooks_self') return I18n.t('habitCooksSelf');
    if (v === 'rarely' || v === 'never' || v === 'eat_out') return I18n.t('habitEatOut');
    return I18n.t('habitRotates');
  }
  function habitSmoke(v) {
    if (v === 'no') return I18n.t('habitNoSmoke');
    if (v === 'outside' || v === 'balcony') return I18n.t('habitOutsideSmoke');
    return I18n.t('habitSmokes');
  }
  function habitSocial(v) {
    if (v === 'introvert') return I18n.t('habitIntrovert');
    if (v === 'extrovert') return I18n.t('habitExtrovert');
    return I18n.t('habitBalanced');
  }
  function habitLabels(p) {
    return [
      habitSleep(p.sleep_schedule),
      habitClean(p.cleanliness),
      habitStudy(p.study_habit),
      habitSmoke(p.smoking_habit),
    ].filter(Boolean);
  }

  function optionUnis(selected, includeEmpty) {
    let html = includeEmpty !== false
      ? `<option value="">${esc(I18n.t('allUnis'))}</option>` : '';
    state.unis.forEach((u) => {
      const id = String(u.id);
      html += `<option value="${esc(id)}"${id === String(selected || '') ? ' selected' : ''}>${esc(u.short_name || u.name_uz)}</option>`;
    });
    return html;
  }

  function uniChipsHtml(selectedId, chipClass) {
    const cls = chipClass || '';
    let html = `<button type="button" class="chip${cls}${!selectedId ? ' active' : ''}" data-uni="">${esc(I18n.t('allUnis'))}</button>`;
    state.unis.forEach((u) => {
      const id = String(u.id);
      const on = id === String(selectedId || '');
      html += `<button type="button" class="chip${cls}${on ? ' active' : ''}" data-uni="${esc(id)}">🎓 ${esc(u.short_name || u.name_uz)}</button>`;
    });
    return html;
  }

  function applyTheme(mode) {
    const m = mode || localStorage.getItem(Api.KEYS.theme) || 'system';
    localStorage.setItem(Api.KEYS.theme, m);
    let resolved = m;
    if (m === 'system') {
      resolved = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    }
    document.documentElement.setAttribute('data-theme', resolved);
  }

  function closeModal() {
    const root = $('#modalRoot');
    if (root) root.innerHTML = '';
  }

  function openModal(html) {
    openSheet(html);
  }

  function openSheet(html) {
    const root = $('#modalRoot');
    root.innerHTML = `<div class="overlay" id="sheetOverlay"><div class="sheet" role="dialog">${html}</div></div>`;
    $('#sheetOverlay').addEventListener('click', (e) => {
      if (e.target.id === 'sheetOverlay') closeModal();
    });
  }

  function getCachedProfile() {
    try { return JSON.parse(localStorage.getItem(PROFILE_CACHE) || 'null'); }
    catch { return null; }
  }

  function setCachedProfile(p) {
    if (p) localStorage.setItem(PROFILE_CACHE, JSON.stringify(p));
    else localStorage.removeItem(PROFILE_CACHE);
  }

  function groupCode() {
    return localStorage.getItem(Api.KEYS.group) || 'home_default';
  }

  function setGroupCode(c) {
    localStorage.setItem(Api.KEYS.group, c || 'home_default');
  }

  async function shareOrCopy(url, title) {
    try {
      if (navigator.share) {
        await navigator.share({ title: title || 'XonaDosh', url });
        return;
      }
    } catch (_) { /* user cancelled or unsupported */ }
    try {
      await navigator.clipboard.writeText(url);
      toast(I18n.t('linkCopied'));
    } catch {
      prompt(I18n.t('share'), url);
    }
  }

  /* ─── routing ─────────────────────────────────────────── */
  function parseHash() {
    const raw = (location.hash || '#/housing').replace(/^#\/?/, '');
    const parts = raw.split('/').filter(Boolean);
    const head = parts[0] || 'housing';
    if (head === 'listing' && parts[1]) {
      return { route: 'listing', params: { id: parts[1] } };
    }
    const known = [
      'login', 'register', 'housing', 'matching', 'coliving',
      'settings', 'map', 'create-listing', 'profile',
    ];
    return { route: known.includes(head) ? head : 'housing', params: {} };
  }

  function navigate(path) {
    const p = path.startsWith('#') ? path : '#/' + path.replace(/^\//, '');
    if (location.hash === p) route();
    else location.hash = p;
  }

  function isAuthRoute(r) {
    return r === 'login' || r === 'register';
  }

  function route() {
    const { route: r, params } = parseHash();
    state.route = r;
    state.params = params;

    if (!Api.isLoggedIn() && !isAuthRoute(r)) {
      navigate('login');
      return;
    }
    if (Api.isLoggedIn() && isAuthRoute(r)) {
      navigate('housing');
      return;
    }

    if (isAuthRoute(r)) {
      $('#authRoot').classList.remove('hidden');
      $('#appRoot').classList.add('hidden');
      renderAuth(r);
      return;
    }

    $('#authRoot').classList.add('hidden');
    $('#appRoot').classList.remove('hidden');
    updateChrome(r);
    renderMain(r, params);
  }

  function updateChrome(r) {
    const tab = (r === 'matching' || r === 'profile') ? 'matching'
      : (r === 'coliving') ? 'coliving' : 'housing';
    $$('#bottomNav button').forEach((b) => {
      b.classList.toggle('active', b.dataset.tab === tab);
    });
    const subMap = {
      housing: I18n.t('housingSub'),
      matching: I18n.t('matchingSub'),
      profile: I18n.t('matchingSub'),
      coliving: I18n.t('colivingSub'),
      settings: I18n.t('settings'),
      map: I18n.t('map'),
      'create-listing': I18n.t('createListing'),
      listing: I18n.t('housing'),
    };
    $('#topSubtitle').textContent = subMap[r] || I18n.t('housingSub');
    $$('[data-i18n]').forEach((el) => {
      const k = el.getAttribute('data-i18n');
      if (k) el.textContent = I18n.t(k);
    });
  }

  /* ─── auth ────────────────────────────────────────────── */
  function renderAuth(mode) {
    const isReg = mode === 'register';
    $('#authRoot').innerHTML = `
      <div class="auth-wrap">
        <div class="panel auth-card stack">
          <img class="logo" src="/assets/brand/xonadosh_logo_ui.png" alt="XonaDosh" width="220" height="220" />
          <h2 style="margin:0;font-family:Outfit,sans-serif">${esc(isReg ? I18n.t('register') : I18n.t('welcome'))}</h2>
          <p class="muted" style="margin:0">${esc(I18n.t('tagline'))}</p>
          <form id="authForm" class="stack">
            ${isReg ? `
              <div class="field"><label>${esc(I18n.t('fullName'))}</label>
                <input name="full_name" required autocomplete="name" /></div>
              <div class="field"><label>${esc(I18n.t('phone'))}</label>
                <input name="phone_number" required placeholder="+998…" autocomplete="tel" /></div>
            ` : ''}
            <div class="field"><label>${esc(I18n.t('username'))}</label>
              <input name="username" required autocomplete="username" value="${isReg ? '' : 'demo'}" /></div>
            <div class="field"><label>${esc(I18n.t('password'))}</label>
              <input name="password" type="password" required autocomplete="${isReg ? 'new-password' : 'current-password'}" value="${isReg ? '' : 'Demo1234!'}" /></div>
            ${isReg ? `
              <div class="field"><label>${esc(I18n.t('password'))} (2)</label>
                <input name="password2" type="password" required autocomplete="new-password" /></div>
            ` : ''}
            <p class="err hidden" id="authErr"></p>
            <button class="btn btn-primary btn-block" type="submit">${esc(isReg ? I18n.t('createAccount') : I18n.t('login'))}</button>
          </form>
          <p class="muted" style="font-size:.85rem;margin:0">
            ${isReg
              ? `${esc(I18n.t('haveAccount'))} <a href="#/login">${esc(I18n.t('login'))}</a>`
              : `${esc(I18n.t('noAccount'))} <a href="#/register">${esc(I18n.t('register'))}</a>`}
          </p>
          ${!isReg ? `<p class="muted" style="font-size:.8rem;margin:0">Demo: <code>demo</code> / <code>Demo1234!</code></p>` : ''}
        </div>
      </div>`;

    $('#authForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const fd = new FormData(e.target);
      const errEl = $('#authErr');
      errEl.classList.add('hidden');
      const username = String(fd.get('username') || '').trim();
      const password = String(fd.get('password') || '');
      if (isReg) {
        if (password !== String(fd.get('password2') || '')) {
          errEl.textContent = 'Parollar mos emas';
          errEl.classList.remove('hidden');
          return;
        }
        const res = await Api.register({
          username,
          password,
          full_name: String(fd.get('full_name') || '').trim(),
          phone_number: String(fd.get('phone_number') || '').trim(),
        });
        if (!res.ok) {
          errEl.textContent = res.error || 'Xato';
          errEl.classList.remove('hidden');
          return;
        }
        Api.saveAuth(res);
        toast(I18n.t('welcome'));
        navigate('housing');
      } else {
        const res = await Api.login({ username, password });
        if (!res.ok) {
          errEl.textContent = res.error || 'Xato';
          errEl.classList.remove('hidden');
          return;
        }
        Api.saveAuth(res);
        toast(I18n.t('welcome'));
        navigate('housing');
      }
    });
  }

  /* ─── main router ─────────────────────────────────────── */
  function renderMain(r, params) {
    if (state.mapInstance) {
      try { state.mapInstance.remove(); } catch (_) { /* */ }
      state.mapInstance = null;
    }
    const main = $('#main');
    switch (r) {
      case 'housing': renderHousing(main); break;
      case 'matching': renderMatching(main); break;
      case 'coliving': renderColiving(main); break;
      case 'settings': renderSettings(main); break;
      case 'map': renderMap(main); break;
      case 'create-listing': renderCreateListing(main); break;
      case 'listing': renderListingDetail(main, params.id); break;
      case 'profile': renderProfileForm(main); break;
      default: renderHousing(main);
    }
  }

  async function ensureUnis() {
    if (state.unis.length) return state.unis;
    const res = await Api.universities();
    if (res.ok && Array.isArray(res.universities)) state.unis = res.universities;
    return state.unis;
  }

  /* ─── housing ─────────────────────────────────────────── */
  async function renderHousing(main) {
    await ensureUnis();
    const f = state.listingFilters;
    const region = f.city
      ? Locations.regions.find((r) => r.name === f.city)
      : null;
    const districts = region ? region.districts : [];

    main.innerHTML = `
      <div class="stack housing-view">
        <div class="search-map-row">
          <div class="field grow">
            <input id="hsSearch" type="search" placeholder="${esc(I18n.t('search'))}" value="${esc(f.q)}" />
          </div>
          <button type="button" class="map-btn-filled" id="hsMap" title="${esc(I18n.t('map'))}" aria-label="${esc(I18n.t('map'))}">
            <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M9 18l-6 3V6l6-3 6 3 6-3v15l-6 3-6-3z"/><path d="M9 3v15M15 6v15"/>
            </svg>
          </button>
        </div>

        <div class="filter-label">${esc(I18n.t('region'))}</div>
        <div class="pill-row scroll-x" id="hsRegionChips">
          <button type="button" class="chip${!f.city ? ' active' : ''}" data-city="">${esc(I18n.t('all'))}</button>
          ${Locations.regions.map((r) => `
            <button type="button" class="chip${f.city === r.name ? ' active' : ''}" data-city="${esc(r.name)}">${esc(r.flag || '')} ${esc(r.name)}</button>
          `).join('')}
        </div>

        ${region ? `
          <div class="pill-row scroll-x" id="hsDistrictChips">
            <button type="button" class="chip chip-indigo${!f.district ? ' active' : ''}" data-district="">${esc(I18n.t('allDistricts'))}</button>
            ${districts.map((d) => `
              <button type="button" class="chip chip-indigo${f.district === d ? ' active' : ''}" data-district="${esc(d)}">${esc(d)}</button>
            `).join('')}
          </div>
        ` : ''}

        <div class="filter-label">${esc(I18n.t('nearUni'))}</div>
        <div class="pill-row scroll-x" id="hsUniChips">${uniChipsHtml(state.selectedUniId)}</div>

        <div class="pill-row scroll-x" id="hsTypeGender">
          ${[['all', I18n.t('all'), ''], ['rent', I18n.t('rent'), 'type-rent'], ['roommate_wanted', I18n.t('roommate'), 'type-roommate'], ['sell', I18n.t('sell'), 'type-sell'], ['buy', I18n.t('buy'), 'type-buy']]
            .map(([v, l, c]) => {
              const meta = TYPE_META[v];
              const ico = meta ? meta.icon + ' ' : '';
              const on = f.type === v;
              return `<button type="button" class="chip chip-type ${c}${on ? ' active filled' : ''}" data-type="${v}">${ico}${esc(l)}</button>`;
            }).join('')}
          <span class="chip-sep"></span>
          ${[['any', I18n.t('any'), ''], ['boys', I18n.t('boys'), '👨'], ['girls', I18n.t('girls'), '👩']]
            .map(([v, l, ico]) => {
              const on = f.gender === v;
              return `<button type="button" class="chip${on ? ' active filled' : ''}" data-gender="${v}">${ico ? ico + ' ' : ''}${esc(l)}</button>`;
            }).join('')}
        </div>

        <div id="hsList">${spinner()}</div>
      </div>
      <button type="button" class="fab fab-extended" id="hsFab">
        <span class="fab-ico">+</span>
        <span>${esc(I18n.t('postListing'))}</span>
      </button>`;

    $('#hsSearch').addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        state.listingFilters.q = $('#hsSearch').value.trim();
        loadListings();
      }
    });
    $('#hsSearch').addEventListener('change', () => {
      state.listingFilters.q = $('#hsSearch').value.trim();
      loadListings();
    });
    $('#hsMap').addEventListener('click', () => navigate('map'));
    $('#hsFab').addEventListener('click', () => navigate('create-listing'));

    $$('#hsRegionChips .chip').forEach((c) => {
      c.addEventListener('click', () => {
        state.listingFilters.city = c.dataset.city || '';
        state.listingFilters.district = '';
        renderHousing(main);
      });
    });
    $$('#hsDistrictChips .chip').forEach((c) => {
      c.addEventListener('click', () => {
        state.listingFilters.district = c.dataset.district || '';
        $$('#hsDistrictChips .chip').forEach((x) => x.classList.toggle('active', x === c));
        loadListings();
      });
    });
    $$('#hsUniChips .chip').forEach((c) => {
      c.addEventListener('click', () => {
        state.selectedUniId = c.dataset.uni || '';
        $$('#hsUniChips .chip').forEach((x) => x.classList.toggle('active', x === c));
        loadListings();
      });
    });
    $$('#hsTypeGender [data-type]').forEach((c) => {
      c.addEventListener('click', () => {
        const t = c.dataset.type;
        state.listingFilters.type = (state.listingFilters.type === t && t !== 'all') ? 'all' : t;
        renderHousing(main);
      });
    });
    $$('#hsTypeGender [data-gender]').forEach((c) => {
      c.addEventListener('click', () => {
        const g = c.dataset.gender;
        state.listingFilters.gender = (state.listingFilters.gender === g && g !== 'any') ? 'any' : g;
        $$('#hsTypeGender [data-gender]').forEach((x) => {
          x.classList.toggle('active', x.dataset.gender === state.listingFilters.gender);
          x.classList.toggle('filled', x.dataset.gender === state.listingFilters.gender);
        });
        loadListings();
      });
    });

    loadListings();
  }

  function clearHousingFilters() {
    state.listingFilters = { q: '', type: 'all', city: '', district: '', gender: 'any' };
    state.selectedUniId = '';
  }

  async function loadListings() {
    const box = $('#hsList');
    if (!box) return;
    box.innerHTML = spinner();
    const f = state.listingFilters;
    const q = {
      q: f.q || undefined,
      type: f.type === 'all' ? undefined : f.type,
      city: f.city || undefined,
      district: f.district || undefined,
      gender: f.gender === 'any' ? undefined : f.gender,
      university_id: state.selectedUniId || undefined,
      limit: 40,
    };
    const res = await Api.listings(q);
    if (!res.ok) {
      box.innerHTML = errBox(res.error, 'hsRetry');
      const btn = $('#hsRetry');
      if (btn) btn.addEventListener('click', loadListings);
      return;
    }
    const items = res.listings || [];
    state.listings = items;
    if (!items.length) {
      box.innerHTML = emptyState(
        I18n.t('emptyListings'),
        '⌂',
        `<p class="muted" style="font-size:.85rem">${esc(I18n.t('emptyListingsHint'))}</p>
         <button type="button" class="btn btn-primary btn-sm" id="hsClearFilters">${esc(I18n.t('clearFilters'))}</button>`
      );
      const clr = $('#hsClearFilters');
      if (clr) {
        clr.addEventListener('click', () => {
          clearHousingFilters();
          renderHousing($('#main'));
        });
      }
      return;
    }
    box.innerHTML = `<div class="stack">${items.map(listingCardHtml).join('')}</div>`;
    $$('.listing-card', box).forEach((el) => {
      el.addEventListener('click', () => navigate('listing/' + el.dataset.id));
    });
  }

  function listingCardHtml(L) {
    const photo = (L.photos && L.photos[0]) || '';
    const gender = L.target_gender || 'any';
    const period = periodLabel(L.price_period || 'month');

    return `<article class="card listing-card" data-id="${esc(L.id)}">
      <div class="listing-media">
        ${photo
          ? `<img src="${esc(photo)}" alt="" loading="lazy" />`
          : `<div class="listing-placeholder">⌂</div>`}
        <span class="listing-type-badge ${typeClass(L.type)}">${typeIcon(L.type)} ${esc(typeLabel(L.type))}</span>
        ${gender !== 'any' ? `<span class="listing-gender-badge">${esc(genderLabel(gender))}</span>` : ''}
      </div>
      <div class="listing-body">
        <div class="price-tag">${esc(money(L.price, L.currency))} <small style="font-size:.8rem;color:var(--muted);font-weight:600">/ ${esc(period)}</small></div>
        <h3>${esc(L.title)}</h3>
        <p class="loc">📍 ${esc([L.city, L.district].filter(Boolean).join(' • ') || L.address || '—')}</p>
        <div class="listing-specs">
          <span class="spec-pill">🛏️ ${esc(L.rooms_count || 1)} xona</span>
          <span class="spec-pill">📐 ${esc(L.area_sqm || 0)} m²</span>
          <span class="spec-pill">🏢 ${esc(L.floor || 1)}/${esc(L.total_floors || 1)}-qavat</span>
          ${L.nearest_university_short ? `<span class="spec-pill uni">🎓 ${esc(L.nearest_university_short)}</span>` : ''}
        </div>
      </div>
    </article>`;
  }

  /* ─── listing detail ──────────────────────────────────── */
  async function renderListingDetail(main, id) {
    main.innerHTML = spinner();
    const res = await Api.listings({ id, limit: 1 });
    const item = (res.listings && res.listings[0]) || state.listings.find((x) => String(x.id) === String(id));
    if (!res.ok && !item) {
      main.innerHTML = errBox(res.error || 'Not found');
      return;
    }
    if (!item) {
      main.innerHTML = emptyState(I18n.t('emptyListings'));
      return;
    }
    const me = Api.getUser();
    const isOwner = me && me.username && item.username && me.username === item.username;
    const photos = item.photos || [];
    const amenities = item.amenities || [];
    const priceStr = money(item.price, item.currency) + ' / ' + periodLabel(item.price_period || 'month');
    const shareUrl = location.origin + location.pathname + '#/listing/' + item.id;

    main.innerHTML = `
      <div class="stack">
        <div class="row between">
          <button type="button" class="btn btn-ghost btn-sm" id="ldBack">←</button>
          <button type="button" class="btn btn-ghost btn-sm" id="ldShare">${esc(I18n.t('share'))}</button>
        </div>
        ${photos.length ? `
          <div class="photo-carousel" id="ldCarousel">
            ${photos.map((p, i) => `<img src="${esc(p)}" alt="" class="${i === 0 ? 'active' : ''}" data-idx="${i}" loading="lazy" />`).join('')}
            ${photos.length > 1 ? `
              <button type="button" class="carousel-nav prev" id="ldPrev">‹</button>
              <button type="button" class="carousel-nav next" id="ldNext">›</button>
              <div class="carousel-dots">${photos.map((_, i) => `<span class="dot${i === 0 ? ' on' : ''}" data-i="${i}"></span>`).join('')}</div>
            ` : ''}
          </div>` : `<div class="listing-placeholder tall">⌂</div>`}
        <div class="panel stack">
          <div class="row between">
            <span class="listing-type-badge inline ${typeClass(item.type)}">${typeIcon(item.type)} ${esc(typeLabel(item.type))}</span>
            <span class="price">${esc(priceStr)}</span>
          </div>
          <h2 style="margin:0;font-family:Outfit,sans-serif">${esc(item.title)}</h2>
          <p class="muted" style="margin:0">${esc(item.address || '')} · ${esc(item.district || '')}, ${esc(item.city || '')}</p>
          <p style="margin:0">${esc(item.rooms_count || 0)} ${esc(I18n.t('rooms'))} · ${esc(item.floor || 0)}/${esc(item.total_floors || 0)} ${esc(I18n.t('floor'))} · ${esc(item.area_sqm || 0)} m² · ${esc(genderLabel(item.target_gender))}</p>
          ${item.description ? `<p>${esc(item.description)}</p>` : ''}
          ${amenities.length ? `<div><p class="section-title" style="font-size:.95rem">${esc(I18n.t('amenities'))}</p>
            <div class="pill-row">${amenities.map((a) => `<span class="chip active">${esc(a)}</span>`).join('')}</div></div>` : ''}
          <div class="row">
            ${item.phone_number ? `<a class="btn btn-primary btn-sm" href="${esc(telHref(item.phone_number))}">${esc(I18n.t('call'))}</a>` : ''}
            ${item.telegram_handle ? `<a class="btn btn-ghost btn-sm" href="${esc(tgHref(item.telegram_handle))}" target="_blank" rel="noopener">${esc(I18n.t('telegram'))}</a>` : ''}
            <button type="button" class="btn btn-ghost btn-sm" id="ldCommute">${esc(I18n.t('commute'))}</button>
            ${isOwner ? `<button type="button" class="btn btn-danger btn-sm" id="ldDel">${esc(I18n.t('delete'))}</button>` : ''}
          </div>
        </div>
        <div id="ldCommuteBox"></div>
      </div>`;

    $('#ldBack').addEventListener('click', () => navigate('housing'));
    $('#ldShare').addEventListener('click', () => shareOrCopy(shareUrl, item.title));

    if (photos.length > 1) {
      let idx = 0;
      const show = (n) => {
        idx = (n + photos.length) % photos.length;
        $$('#ldCarousel img').forEach((img, i) => img.classList.toggle('active', i === idx));
        $$('#ldCarousel .dot').forEach((d, i) => d.classList.toggle('on', i === idx));
      };
      $('#ldPrev').addEventListener('click', () => show(idx - 1));
      $('#ldNext').addEventListener('click', () => show(idx + 1));
      $$('#ldCarousel .dot').forEach((d) => {
        d.addEventListener('click', () => show(Number(d.dataset.i)));
      });
    }

    if (isOwner) {
      $('#ldDel').addEventListener('click', async () => {
        if (!confirm(I18n.t('confirmDelete'))) return;
        const r = await Api.deleteListing(item.id);
        if (!r.ok) { toast(r.error || 'Xato'); return; }
        toast(I18n.t('done'));
        navigate('housing');
      });
    }
    $('#ldCommute').addEventListener('click', () => showCommuteSheet(item));
  }

  async function showCommuteSheet(item) {
    await ensureUnis();
    const uniId = item.nearest_university_id || state.selectedUniId || (state.unis[0] && state.unis[0].id) || '';
    openSheet(`
      <div class="handle"></div>
      <h3 class="section-title">${esc(I18n.t('commute'))}</h3>
      <div class="field"><label>${esc(I18n.t('university'))}</label>
        <select id="cmUni">${optionUnis(uniId, false)}</select></div>
      <button type="button" class="btn btn-primary btn-block" id="cmGo">${esc(I18n.t('calculate'))}</button>
      <div id="cmResult" class="stack" style="margin-top:.75rem"></div>
      <button type="button" class="btn btn-ghost btn-block" id="cmClose">${esc(I18n.t('cancel'))}</button>`);
    $('#cmClose').addEventListener('click', closeModal);
    $('#cmGo').addEventListener('click', async () => {
      const box = $('#cmResult');
      box.innerHTML = spinner();
      const uid = $('#cmUni').value;
      const res = await Api.commute({
        from_lat: item.latitude,
        from_lng: item.longitude,
        university_id: uid,
        listing_id: item.id,
      });
      if (!res.ok) {
        box.innerHTML = `<p class="err">${esc(res.error || 'Xato')}</p>`;
        return;
      }
      const modes = res.modes || {};
      const order = ['metro', 'bus', 'taxi', 'bicycle', 'walk'];
      const labels = { metro: 'Metro', bus: 'Avtobus', taxi: 'Taksi', bicycle: 'Velosiped', walk: 'Piyoda' };
      let html = `<p class="muted">${esc(res.university?.short_name || '')} · ${esc(res.distance?.road_km || '')} km</p>`;
      order.forEach((k) => {
        const m = modes[k];
        if (!m) return;
        html += `<div class="card" style="cursor:default">
          <div class="row between"><strong>${esc(labels[k] || m.name)}</strong>
            <span>${esc(m.time_min)} min</span></div>
          <p class="muted" style="margin:.3rem 0 0;font-size:.85rem">
            ${m.fare_uzs ? esc(money(m.fare_uzs)) + ' / ' : ''}
            ${m.monthly_budget_uzs != null ? esc(money(m.monthly_budget_uzs)) + ' / oy' : ''}
            ${m.calories_kcal ? ' · ' + esc(m.calories_kcal) + ' kkal' : ''}
            ${m.distance_km != null ? ' · ' + esc(m.distance_km) + ' km' : ''}
          </p>
        </div>`;
      });
      box.innerHTML = html;
    });
  }

  /* ─── create listing ──────────────────────────────────── */
  async function renderCreateListing(main) {
    if (!Api.isLoggedIn()) {
      main.innerHTML = emptyState(I18n.t('needAuth'));
      return;
    }
    await ensureUnis();
    const user = Api.getUser() || {};
    if (!state.createPhotos.length && Locations.presetPhotos && Locations.presetPhotos[0]) {
      state.createPhotos = [Locations.presetPhotos[0].url];
    }
    const regions = Locations.regions;
    const city0 = regions[0] ? regions[0].name : 'Toshkent shahri';
    const dists = Locations.districtsFor(city0);

    main.innerHTML = `
      <div class="panel stack">
        <button type="button" class="btn btn-ghost btn-sm" id="clBack">←</button>
        <h2 class="section-title">${esc(I18n.t('createListing'))}</h2>
        <form id="clForm" class="stack">
          <div class="field"><label>${esc(I18n.t('title'))}</label><input name="title" required /></div>
          <div class="field"><label>Type</label>
            <select name="type">
              <option value="rent">${esc(I18n.t('rent'))}</option>
              <option value="roommate_wanted">${esc(I18n.t('roommate'))}</option>
              <option value="sell">${esc(I18n.t('sell'))}</option>
              <option value="buy">${esc(I18n.t('buy'))}</option>
            </select></div>
          <div class="grid-2">
            <div class="field"><label>${esc(I18n.t('price'))}</label><input name="price" type="number" min="1" required value="1500000" /></div>
            <div class="field"><label>${esc(I18n.t('currency'))}</label>
              <select name="currency">
                ${['UZS', 'USD', 'EUR', 'RUB'].map((c) => `<option value="${c}"${c === 'UZS' ? ' selected' : ''}>${c} (${esc(Locations.currencySymbols[c] || c)})</option>`).join('')}
              </select></div>
          </div>
          <div class="field"><label>${esc(I18n.t('pricePeriod'))}</label>
            <select name="price_period">
              <option value="month" selected>${esc(I18n.t('periodMonth'))}</option>
              <option value="day">${esc(I18n.t('periodDay'))}</option>
              <option value="year">${esc(I18n.t('periodYear'))}</option>
              <option value="total">${esc(I18n.t('periodTotal'))}</option>
            </select></div>
          <div class="grid-2">
            <div class="field"><label>${esc(I18n.t('region'))}</label>
              <select name="city" id="clCity">
                ${regions.map((r) => `<option value="${esc(r.name)}">${esc(r.flag || '')} ${esc(r.name)}</option>`).join('')}
              </select></div>
            <div class="field"><label>${esc(I18n.t('district'))}</label>
              <select name="district" id="clDistrict">
                ${dists.map((d) => `<option value="${esc(d)}">${esc(d)}</option>`).join('')}
              </select></div>
          </div>
          <div class="field"><label>${esc(I18n.t('address'))}</label><input name="address" /></div>
          <div class="grid-2">
            <div class="field"><label>${esc(I18n.t('phone'))}</label><input name="phone_number" required value="${esc(user.phone_number || '')}" /></div>
            <div class="field"><label>${esc(I18n.t('telegram'))}</label><input name="telegram_handle" placeholder="@user" /></div>
          </div>
          <div class="grid-2">
            <div class="field"><label>${esc(I18n.t('rooms'))}</label><input name="rooms_count" type="number" min="1" value="2" /></div>
            <div class="field"><label>${esc(I18n.t('floor'))}</label><input name="floor" type="number" value="3" /></div>
          </div>
          <div class="grid-2">
            <div class="field"><label>${esc(I18n.t('floor'))} (jami)</label><input name="total_floors" type="number" value="5" /></div>
            <div class="field"><label>m²</label><input name="area_sqm" type="number" value="55" /></div>
          </div>
          <div class="grid-2">
            <div class="field"><label>${esc(I18n.t('gender'))}</label>
              <select name="target_gender">
                <option value="any">${esc(I18n.t('any'))}</option>
                <option value="boys">${esc(I18n.t('boys'))}</option>
                <option value="girls">${esc(I18n.t('girls'))}</option>
                <option value="family">${esc(I18n.t('family'))}</option>
              </select></div>
            <div class="field"><label>${esc(I18n.t('university'))}</label>
              <select name="nearest_university_id">${optionUnis(state.selectedUniId)}</select></div>
          </div>
          <div class="grid-2">
            <div class="field"><label>Lat</label><input name="latitude" type="number" step="any" value="${TASHKENT.lat}" /></div>
            <div class="field"><label>Lng</label><input name="longitude" type="number" step="any" value="${TASHKENT.lng}" /></div>
          </div>
          <div class="field"><label>${esc(I18n.t('description'))}</label><textarea name="description"></textarea></div>

          <div>
            <p class="section-title" style="font-size:.95rem">${esc(I18n.t('photos'))}</p>
            <div class="row" id="clPhotoList">
              ${state.createPhotos.map((u, i) => `
                <div class="photo-thumb" data-i="${i}">
                  <img src="${esc(u)}" alt="" />
                  <button type="button" class="photo-rm" data-i="${i}">×</button>
                </div>`).join('')}
            </div>
            <div class="row" style="margin-top:.5rem">
              <div class="field grow"><label>${esc(I18n.t('photoUrl'))}</label>
                <input id="clPhotoUrl" type="url" placeholder="https://…" /></div>
              <button type="button" class="btn btn-ghost btn-sm" id="clAddPhoto" style="margin-top:1.2rem">${esc(I18n.t('addPhoto'))}</button>
            </div>
            <div class="pill-row" style="margin-top:.5rem" id="clPresets">
              ${(Locations.presetPhotos || []).map((p) => `
                <button type="button" class="chip" data-url="${esc(p.url)}">${esc(p.title)}</button>`).join('')}
            </div>
          </div>

          <div><p class="section-title" style="font-size:.95rem">${esc(I18n.t('amenities'))}</p>
            <div class="stack" id="clAmenities">
              ${AMENITIES.map((a) => {
                const checked = ['Wi-Fi', 'Kir yuvish mashinasi', 'Muzlatgich', 'Issiq suv'].includes(a);
                return `<label class="check"><input type="checkbox" name="amenity" value="${esc(a)}"${checked ? ' checked' : ''} /><span>${esc(a)}</span></label>`;
              }).join('')}
            </div>
          </div>
          <p class="err hidden" id="clErr"></p>
          <button class="btn btn-primary btn-block" type="submit">${esc(I18n.t('save'))}</button>
        </form>
      </div>`;

    const refreshPhotoList = () => {
      const box = $('#clPhotoList');
      if (!box) return;
      box.innerHTML = state.createPhotos.map((u, i) => `
        <div class="photo-thumb" data-i="${i}">
          <img src="${esc(u)}" alt="" />
          <button type="button" class="photo-rm" data-i="${i}">×</button>
        </div>`).join('');
      $$('.photo-rm', box).forEach((b) => {
        b.addEventListener('click', () => {
          state.createPhotos.splice(Number(b.dataset.i), 1);
          refreshPhotoList();
        });
      });
    };
    refreshPhotoList();

    $('#clCity').addEventListener('change', () => {
      const ds = Locations.districtsFor($('#clCity').value);
      $('#clDistrict').innerHTML = ds.map((d) => `<option value="${esc(d)}">${esc(d)}</option>`).join('');
    });
    $('#clAddPhoto').addEventListener('click', () => {
      const url = ($('#clPhotoUrl').value || '').trim();
      if (!url) return;
      state.createPhotos.push(url);
      $('#clPhotoUrl').value = '';
      refreshPhotoList();
    });
    $$('#clPresets .chip').forEach((c) => {
      c.addEventListener('click', () => {
        const url = c.dataset.url;
        if (url && !state.createPhotos.includes(url)) {
          state.createPhotos.push(url);
          refreshPhotoList();
        }
      });
    });

    $('#clBack').addEventListener('click', () => navigate('housing'));
    $('#clForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const fd = new FormData(e.target);
      const amenities = $$('input[name="amenity"]:checked').map((x) => x.value);
      const photos = state.createPhotos.length
        ? state.createPhotos.slice()
        : [(Locations.presetPhotos && Locations.presetPhotos[0] && Locations.presetPhotos[0].url) || ''];
      const payload = {
        title: String(fd.get('title') || '').trim(),
        type: String(fd.get('type') || 'rent'),
        price: Number(fd.get('price') || 0),
        currency: String(fd.get('currency') || 'UZS'),
        price_period: String(fd.get('price_period') || 'month'),
        city: String(fd.get('city') || city0),
        district: String(fd.get('district') || ''),
        address: String(fd.get('address') || ''),
        phone_number: String(fd.get('phone_number') || ''),
        telegram_handle: String(fd.get('telegram_handle') || ''),
        rooms_count: Number(fd.get('rooms_count') || 2),
        floor: Number(fd.get('floor') || 1),
        total_floors: Number(fd.get('total_floors') || 4),
        area_sqm: Number(fd.get('area_sqm') || 50),
        target_gender: String(fd.get('target_gender') || 'any'),
        nearest_university_id: fd.get('nearest_university_id') ? Number(fd.get('nearest_university_id')) : null,
        latitude: Number(fd.get('latitude') || TASHKENT.lat),
        longitude: Number(fd.get('longitude') || TASHKENT.lng),
        description: String(fd.get('description') || ''),
        amenities,
        photos: photos.filter(Boolean),
        owner_name: user.full_name || user.username || '',
      };
      const err = $('#clErr');
      err.classList.add('hidden');
      const res = await Api.createListing(payload);
      if (!res.ok) {
        err.textContent = res.error || 'Xato';
        err.classList.remove('hidden');
        return;
      }
      state.createPhotos = [];
      toast(I18n.t('done'));
      const newId = res.listing_id || res.id;
      navigate(newId ? 'listing/' + newId : 'housing');
    });
  }

  /* ─── map ─────────────────────────────────────────────── */
  async function renderMap(main) {
    await ensureUnis();
    main.innerHTML = `
      <div class="stack">
        <div class="row between">
          <button type="button" class="btn btn-ghost btn-sm" id="mpBack">←</button>
          <div class="field" style="flex:1">
            <select id="mpUni"><option value="">${esc(I18n.t('allUnis'))}</option>${optionUnis(state.selectedUniId, false)}</select>
          </div>
        </div>
        <div class="pill-row scroll-x" id="mpUniChips">${uniChipsHtml(state.selectedUniId)}</div>
        <div id="map"></div>
        <p class="muted" style="font-size:.8rem;margin:0">© OpenStreetMap</p>
      </div>`;
    $('#mpBack').addEventListener('click', () => navigate('housing'));

    const map = L.map('map').setView([TASHKENT.lat, TASHKENT.lng], 12);
    state.mapInstance = map;
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(map);
    const markers = L.layerGroup().addTo(map);

    const load = async () => {
      const uniFilter = state.selectedUniId;
      const listRes = await Api.listings({
        university_id: uniFilter || undefined,
        limit: 80,
      });
      markers.clearLayers();
      (state.unis || []).forEach((u) => {
        if (uniFilter && String(u.id) !== String(uniFilter)) return;
        if (u.latitude == null) return;
        L.marker([u.latitude, u.longitude], { title: u.short_name })
          .addTo(markers)
          .bindPopup(`<strong>${esc(u.short_name || u.name_uz)}</strong><br/>${esc(I18n.t('university'))}`);
      });
      const listings = (listRes.ok && listRes.listings) || [];
      listings.forEach((item) => {
        if (item.latitude == null) return;
        L.circleMarker([item.latitude, item.longitude], {
          radius: 8, color: '#059669', fillColor: '#10b981', fillOpacity: 0.85, weight: 2,
        }).addTo(markers).bindPopup(
          `<strong>${esc(item.title)}</strong><br/>${esc(money(item.price, item.currency))}<br/>
           <a href="#/listing/${esc(item.id)}">${esc(I18n.t('housing'))}</a>`
        );
      });
      setTimeout(() => map.invalidateSize(), 80);
    };

    const bindUni = () => {
      $$('#mpUniChips .chip').forEach((c) => {
        c.addEventListener('click', () => {
          state.selectedUniId = c.dataset.uni || '';
          $('#mpUni').value = state.selectedUniId;
          $$('#mpUniChips .chip').forEach((x) => x.classList.toggle('active', x === c));
          load();
        });
      });
      $('#mpUni').addEventListener('change', () => {
        state.selectedUniId = $('#mpUni').value;
        $$('#mpUniChips .chip').forEach((x) => {
          x.classList.toggle('active', (x.dataset.uni || '') === state.selectedUniId);
        });
        load();
      });
    };
    bindUni();
    load();
  }

  /* ─── matching ────────────────────────────────────────── */
  async function loadMyProfile() {
    const cached = getCachedProfile();
    if (cached) state.myProfile = cached;
    const res = await Api.profiles({ my: 1 });
    if (res.ok && res.profile) {
      state.myProfile = res.profile;
      setCachedProfile(res.profile);
    } else if (res.ok && res.profile === null) {
      state.myProfile = cached;
    }
    return state.myProfile;
  }

  async function renderMatching(main) {
    await ensureUnis();
    const profile = await loadMyProfile();
    const g = state.matchFilters.gender || 'any';
    const hasProfile = profile && (profile.full_name || profile.fullName);

    let bannerHtml;
    if (hasProfile) {
      const name = profile.full_name || profile.fullName || '';
      const initial = name ? name.charAt(0).toUpperCase() : 'U';
      const bMin = Math.round((Number(profile.budget_min) || 0) / 1000);
      const bMax = Math.round((Number(profile.budget_max) || 0) / 1000);
      const uni = profile.university_short || profile.university_name || '';
      bannerHtml = `
        <div class="match-banner-active" id="mtBanner">
          <div class="avatar-circle">${esc(initial)}</div>
          <div class="grow">
            <div class="row" style="gap:.4rem">
              <strong>${esc(name)}</strong>
              <span class="badge badge-em">${esc(I18n.t('active'))}</span>
            </div>
            <p class="muted" style="margin:.2rem 0 0;font-size:.85rem">${esc(uni)} · ${esc(bMin)}k–${esc(bMax)}k so‘m</p>
          </div>
          <button type="button" class="btn btn-purple btn-sm" id="mtEdit">${esc(I18n.t('edit'))}</button>
        </div>`;
    } else {
      bannerHtml = `
        <div class="match-banner-create" id="mtBanner">
          <div class="row" style="gap:.6rem">
            <div class="banner-ico">✦</div>
            <div>
              <strong>${esc(I18n.t('createProfileBanner'))}</strong>
              <p style="margin:.35rem 0 0;opacity:.85;font-size:.85rem">${esc(I18n.t('createProfileHint'))}</p>
            </div>
          </div>
          <button type="button" class="btn btn-on-purple btn-sm" id="mtEdit" style="margin-top:.9rem">${esc(I18n.t('fillProfile'))}</button>
        </div>`;
    }

    main.innerHTML = `
      <div class="stack">
        ${bannerHtml}
        <div class="row between" style="align-items:flex-start">
          <h3 class="section-title" style="margin:0">${esc(I18n.t('recommended'))}</h3>
          <span class="ai-badge">✓ ${esc(I18n.t('aiBadge'))}</span>
        </div>
        <div class="pill-row scroll-x" id="mtGender">
          ${[['any', I18n.t('any'), ''], ['boys', I18n.t('boys'), '👨'], ['girls', I18n.t('girls'), '👩']]
            .map(([v, l, ico]) => `<button type="button" class="chip purple${g === v ? ' active filled' : ''}" data-g="${v}">${ico ? ico + ' ' : ''}${esc(l)}</button>`).join('')}
        </div>
        <div class="pill-row scroll-x" id="mtUniChips">${uniChipsHtml(state.selectedUniId, ' purple')}</div>
        <div id="mtList">${spinner()}</div>
      </div>`;

    const goProfile = () => navigate('profile');
    $('#mtBanner').addEventListener('click', (e) => {
      if (e.target.id === 'mtEdit' || e.target.closest('#mtEdit') || e.target.id === 'mtBanner' || e.target.closest('#mtBanner')) {
        goProfile();
      }
    });
    const editBtn = $('#mtEdit');
    if (editBtn) editBtn.addEventListener('click', (e) => { e.stopPropagation(); goProfile(); });

    $$('#mtGender .chip').forEach((c) => {
      c.addEventListener('click', () => {
        state.matchFilters.gender = c.dataset.g || 'any';
        $$('#mtGender .chip').forEach((x) => {
          const on = x === c;
          x.classList.toggle('active', on);
          x.classList.toggle('filled', on);
        });
        loadMatches();
      });
    });
    $$('#mtUniChips .chip').forEach((c) => {
      c.addEventListener('click', () => {
        state.selectedUniId = c.dataset.uni || '';
        $$('#mtUniChips .chip').forEach((x) => x.classList.toggle('active', x === c));
        loadMatches();
      });
    });
    loadMatches();
  }

  async function loadMatches() {
    const box = $('#mtList');
    if (!box) return;
    box.innerHTML = spinner();
    const g = state.matchFilters.gender;
    let apiGender;
    if (g === 'boys') apiGender = 'male';
    else if (g === 'girls') apiGender = 'female';
    else apiGender = undefined;

    const q = {
      lang: I18n.getLang(),
      gender: apiGender,
      university_id: state.selectedUniId || undefined,
    };
    const res = await Api.match(q);
    if (!res.ok) {
      box.innerHTML = errBox(res.error, 'mtRetry');
      const b = $('#mtRetry');
      if (b) b.addEventListener('click', loadMatches);
      return;
    }
    const matches = res.matches || [];
    if (!matches.length) {
      box.innerHTML = `
        <div class="empty empty-purple">
          <div class="ico purple-circle">♡</div>
          <p><strong>${esc(I18n.t('emptyMatches'))}</strong></p>
          <p class="muted" style="font-size:.85rem">${esc(I18n.t('emptyMatchesHint'))}</p>
          <button type="button" class="btn btn-purple btn-sm" id="mtFillEmpty">${esc(I18n.t('fillProfile'))}</button>
        </div>`;
      const btn = $('#mtFillEmpty');
      if (btn) btn.addEventListener('click', () => navigate('profile'));
      return;
    }
    box.innerHTML = `<div class="stack">${matches.map((m, i) => matchCardHtml(m, i)).join('')}</div>`;
    $$('.match-card', box).forEach((el) => {
      el.addEventListener('click', (e) => {
        if (e.target.closest('a')) return;
        const idx = Number(el.dataset.idx);
        const m = matches[idx];
        if (m) openMatchSheet(m);
      });
    });
  }

  function matchCardHtml(m, idx) {
    const p = m.profile || m;
    const score = m.compatibility_score != null ? m.compatibility_score : (p.compatibility_score || 0);
    const tier = scoreTier(score);
    const reasons = (m.match_reasons || p.match_reasons || []).slice(0, 3);
    const habits = habitLabels(p);
    const name = p.full_name || p.username || '';
    const initial = name ? name.charAt(0).toUpperCase() : 'T';
    const course = p.course_year != null ? `${p.course_year}-${I18n.t('courseYear')}` : '';
    const uni = p.university_short || p.university_name || '';
    const bMax = Math.round((Number(p.budget_max) || 0) / 1000);

    return `<article class="card match-card" data-idx="${idx}">
      <div class="row between">
        <div class="row" style="gap:.75rem;min-width:0;flex:1">
          <div class="avatar-circle sm">${esc(initial)}</div>
          <div style="min-width:0">
            <h3 class="ellipsis">${esc(name)}</h3>
            <p class="muted" style="margin:0;font-size:.85rem">${esc([uni, course].filter(Boolean).join(' · '))}</p>
          </div>
        </div>
        <div class="score ${tier.cls}" style="color:${tier.color}">
          <div>${esc(score)}%</div>
          <div style="font-size:.65rem;font-weight:700">${esc(I18n.t('match'))}</div>
        </div>
      </div>
      ${habits.length ? `<div class="habit-row">${habits.map((h) => `<span class="habit-pill">${esc(h)}</span>`).join('')}</div>` : ''}
      ${reasons.length ? `<div class="reason-row">${reasons.map((r) => `<span class="reason-pill">${esc(r)}</span>`).join('')}</div>` : ''}
      <div class="row between" style="margin-top:.5rem">
        <span class="muted" style="font-size:.85rem">~${esc(bMax)}k so‘m</span>
        <div class="row">
          ${p.phone_number ? `<a class="btn btn-purple btn-sm" href="${esc(telHref(p.phone_number))}" onclick="event.stopPropagation()">${esc(I18n.t('call'))}</a>` : ''}
          ${p.telegram_handle ? `<a class="btn btn-ghost btn-sm" href="${esc(tgHref(p.telegram_handle))}" target="_blank" rel="noopener" onclick="event.stopPropagation()">${esc(I18n.t('telegram'))}</a>` : ''}
        </div>
      </div>
    </article>`;
  }

  function openMatchSheet(m) {
    const p = m.profile || m;
    const score = m.compatibility_score != null ? m.compatibility_score : (p.compatibility_score || 0);
    const reasons = m.match_reasons || p.match_reasons || [];
    const habits = [
      habitSleep(p.sleep_schedule),
      habitClean(p.cleanliness),
      habitStudy(p.study_habit),
      habitCook(p.cooking_habit),
      habitSmoke(p.smoking_habit),
      habitSocial(p.social_habit),
    ];
    openSheet(`
      <div class="handle"></div>
      <div class="row between">
        <h3 class="section-title" style="margin:0">${esc(p.full_name || p.username)}</h3>
        <div class="score ${scoreTier(score).cls}">${esc(score)}%</div>
      </div>
      <p class="muted">${esc(p.university_short || '')} · ${esc(p.course_year || '')}-${esc(I18n.t('courseYear'))}</p>
      ${p.about_me ? `<p class="section-title" style="font-size:.9rem">${esc(I18n.t('about'))}</p><p>${esc(p.about_me)}</p>` : ''}
      ${p.looking_for_text ? `<p class="section-title" style="font-size:.9rem">${esc(I18n.t('lookingFor'))}</p><p>${esc(p.looking_for_text)}</p>` : ''}
      <p class="section-title" style="font-size:.9rem">Habits</p>
      <div class="habit-row">${habits.map((h) => `<span class="habit-pill">${esc(h)}</span>`).join('')}</div>
      ${reasons.length ? `<p class="section-title" style="font-size:.9rem">${esc(I18n.t('match'))}</p>
        <div class="reason-row">${reasons.map((r) => `<span class="reason-pill">${esc(r)}</span>`).join('')}</div>` : ''}
      <div class="row" style="margin-top:1rem">
        ${p.phone_number ? `<a class="btn btn-purple" href="${esc(telHref(p.phone_number))}">${esc(I18n.t('call'))}</a>` : ''}
        ${p.telegram_handle ? `<a class="btn btn-ghost" href="${esc(tgHref(p.telegram_handle))}" target="_blank" rel="noopener">${esc(I18n.t('telegram'))}</a>` : ''}
      </div>
      <button type="button" class="btn btn-ghost btn-block" id="msClose" style="margin-top:.75rem">${esc(I18n.t('cancel'))}</button>`);
    $('#msClose').addEventListener('click', closeModal);
  }

  /* ─── profile form ────────────────────────────────────── */
  async function renderProfileForm(main) {
    await ensureUnis();
    const p = (await loadMyProfile()) || {};
    const user = Api.getUser() || {};
    main.innerHTML = `
      <div class="panel stack">
        <button type="button" class="btn btn-ghost btn-sm" id="pfBack">←</button>
        <h2 class="section-title">${esc(I18n.t('myProfile'))}</h2>
        <form id="pfForm" class="stack">
          <div class="field"><label>${esc(I18n.t('fullName'))}</label>
            <input name="full_name" required value="${esc(p.full_name || user.full_name || '')}" /></div>
          <div class="grid-2">
            <div class="field"><label>${esc(I18n.t('phone'))}</label>
              <input name="phone_number" required value="${esc(p.phone_number || user.phone_number || '')}" /></div>
            <div class="field"><label>${esc(I18n.t('telegram'))}</label>
              <input name="telegram_handle" value="${esc(p.telegram_handle || '')}" /></div>
          </div>
          <div class="grid-2">
            <div class="field"><label>${esc(I18n.t('gender'))}</label>
              <select name="gender">
                <option value="male"${p.gender === 'male' ? ' selected' : ''}>${esc(I18n.t('boys'))}</option>
                <option value="female"${p.gender === 'female' ? ' selected' : ''}>${esc(I18n.t('girls'))}</option>
              </select></div>
            <div class="field"><label>${esc(I18n.t('courseYear'))}</label>
              <input name="course_year" type="number" min="1" max="6" value="${esc(p.course_year || 2)}" /></div>
          </div>
          <div class="field"><label>${esc(I18n.t('university'))}</label>
            <select name="university_id">${optionUnis(p.university_id || state.selectedUniId || '')}</select></div>
          <div class="grid-2">
            <div class="field"><label>Fakultet</label><input name="faculty" value="${esc(p.faculty || '')}" /></div>
            <div class="field"><label>Yosh</label><input name="age" type="number" min="16" max="45" value="${esc(p.age || 20)}" /></div>
          </div>
          <div class="grid-2">
            <div class="field"><label>${esc(I18n.t('budget'))} min</label><input name="budget_min" type="number" value="${esc(p.budget_min || 500000)}" /></div>
            <div class="field"><label>${esc(I18n.t('budget'))} max</label><input name="budget_max" type="number" value="${esc(p.budget_max || 1200000)}" /></div>
          </div>
          <div class="field"><label>${esc(I18n.t('district'))}</label>
            <input name="target_district" value="${esc(p.target_district || '')}" /></div>
          <div class="grid-2">
            <div class="field"><label>Uyqu</label>
              <select name="sleep_schedule">
                ${[['early_bird', I18n.t('habitEarlyBird')], ['night_owl', I18n.t('habitNightOwl')], ['flexible', I18n.t('habitFlexible')]].map(([v, l]) =>
                  `<option value="${v}"${(p.sleep_schedule || 'flexible') === v ? ' selected' : ''}>${esc(l)}</option>`).join('')}
              </select></div>
            <div class="field"><label>Tozalik</label>
              <select name="cleanliness">
                ${[['strict', I18n.t('habitStrict')], ['moderate', I18n.t('habitModerate')], ['relaxed', I18n.t('habitRelaxed')]].map(([v, l]) =>
                  `<option value="${v}"${(p.cleanliness || 'strict') === v ? ' selected' : ''}>${esc(l)}</option>`).join('')}
              </select></div>
          </div>
          <div class="grid-2">
            <div class="field"><label>O‘qish</label>
              <select name="study_habit">
                ${[['silent', I18n.t('habitSilent')], ['music', I18n.t('habitMusic')], ['group', I18n.t('habitGroup')], ['flexible', I18n.t('habitFlexible')]].map(([v, l]) =>
                  `<option value="${v}"${(p.study_habit || 'silent') === v ? ' selected' : ''}>${esc(l)}</option>`).join('')}
              </select></div>
            <div class="field"><label>Oshxona</label>
              <select name="cooking_habit">
                ${[['rotates', I18n.t('habitRotates')], ['often', I18n.t('habitCooksSelf')], ['rarely', I18n.t('habitEatOut')], ['never', I18n.t('habitEatOut')]].map(([v, l]) =>
                  `<option value="${v}"${(p.cooking_habit || 'rotates') === v ? ' selected' : ''}>${esc(l)}</option>`).join('')}
              </select></div>
          </div>
          <div class="grid-2">
            <div class="field"><label>Chekish</label>
              <select name="smoking_habit">
                ${[['no', I18n.t('habitNoSmoke')], ['outside', I18n.t('habitOutsideSmoke')], ['yes', I18n.t('habitSmokes')]].map(([v, l]) =>
                  `<option value="${v}"${(p.smoking_habit || 'no') === v ? ' selected' : ''}>${esc(l)}</option>`).join('')}
              </select></div>
            <div class="field"><label>Ijtimoiy</label>
              <select name="social_habit">
                ${[['balanced', I18n.t('habitBalanced')], ['introvert', I18n.t('habitIntrovert')], ['extrovert', I18n.t('habitExtrovert')]].map(([v, l]) =>
                  `<option value="${v}"${(p.social_habit || 'balanced') === v ? ' selected' : ''}>${esc(l)}</option>`).join('')}
              </select></div>
          </div>
          <div class="field"><label>${esc(I18n.t('about'))}</label>
            <textarea name="about_me">${esc(p.about_me || '')}</textarea></div>
          <div class="field"><label>${esc(I18n.t('lookingFor'))}</label>
            <textarea name="looking_for_text">${esc(p.looking_for_text || '')}</textarea></div>
          <div class="field"><label>Status</label>
            <select name="status">
              <option value="looking"${(p.status || 'looking') === 'looking' ? ' selected' : ''}>${esc(I18n.t('looking'))}</option>
              <option value="paused"${p.status === 'paused' ? ' selected' : ''}>${esc(I18n.t('paused'))}</option>
            </select></div>
          <p class="err hidden" id="pfErr"></p>
          <button class="btn btn-purple btn-block" type="submit">${esc(I18n.t('save'))}</button>
        </form>
      </div>`;

    $('#pfBack').addEventListener('click', () => navigate('matching'));
    $('#pfForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const fd = new FormData(e.target);
      const uniId = fd.get('university_id') ? Number(fd.get('university_id')) : null;
      const uni = state.unis.find((u) => u.id === uniId);
      const payload = {
        full_name: String(fd.get('full_name') || '').trim(),
        phone_number: String(fd.get('phone_number') || '').trim(),
        telegram_handle: String(fd.get('telegram_handle') || '').trim(),
        gender: String(fd.get('gender') || 'male'),
        age: Number(fd.get('age') || 20),
        university_id: uniId,
        university_name: uni ? (uni.name_uz || uni.short_name) : '',
        faculty: String(fd.get('faculty') || ''),
        course_year: Number(fd.get('course_year') || 2),
        budget_min: Number(fd.get('budget_min') || 0),
        budget_max: Number(fd.get('budget_max') || 0),
        target_district: String(fd.get('target_district') || ''),
        sleep_schedule: String(fd.get('sleep_schedule') || 'flexible'),
        cleanliness: String(fd.get('cleanliness') || 'strict'),
        study_habit: String(fd.get('study_habit') || 'silent'),
        cooking_habit: String(fd.get('cooking_habit') || 'rotates'),
        smoking_habit: String(fd.get('smoking_habit') || 'no'),
        social_habit: String(fd.get('social_habit') || 'balanced'),
        about_me: String(fd.get('about_me') || ''),
        looking_for_text: String(fd.get('looking_for_text') || ''),
        status: String(fd.get('status') || 'looking'),
      };
      const err = $('#pfErr');
      err.classList.add('hidden');
      const res = await Api.saveProfile(payload);
      if (!res.ok) {
        err.textContent = res.error || 'Xato';
        err.classList.remove('hidden');
        return;
      }
      const saved = { ...payload, id: res.profile_id };
      state.myProfile = saved;
      setCachedProfile(saved);
      toast(I18n.t('done'));
      navigate('matching');
    });
  }

  /* ─── coliving ────────────────────────────────────────── */
  function renderColiving(main) {
    const sub = state.colivingSub;
    const gc = groupCode();
    main.innerHTML = `
      <div class="stack">
        <div class="panel row between">
          <div class="field" style="flex:1">
            <label>${esc(I18n.t('groupCode'))}</label>
            <input id="cvGroup" value="${esc(gc)}" />
          </div>
          <button type="button" class="btn btn-ghost btn-sm" id="cvGroupSave" style="margin-top:1.2rem">${esc(I18n.t('save'))}</button>
        </div>
        <div class="subtabs" id="cvSubs" style="overflow-x:auto;white-space:nowrap;display:flex;gap:.5rem;padding-bottom:.25rem">
          ${[['chores', '📋 ' + I18n.t('chores')], ['meals', '🍲 ' + I18n.t('meals')], ['grocery', '🛒 ' + I18n.t('grocery')], ['finances', '💰 ' + I18n.t('finances')], ['polls', '🗳 ' + I18n.t('polls')], ['karma', '⭐ ' + I18n.t('karma')]]
            .map(([k, l]) => `<button type="button" class="subtab${sub === k ? ' active' : ''}" data-sub="${k}">${esc(l)}</button>`).join('')}
        </div>
        <div id="cvBody">${spinner()}</div>
      </div>`;

    $('#cvGroupSave').addEventListener('click', () => {
      setGroupCode($('#cvGroup').value.trim() || 'home_default');
      toast(I18n.t('done'));
      loadColivingSub();
    });
    $$('#cvSubs .subtab').forEach((c) => {
      c.addEventListener('click', () => {
        state.colivingSub = c.dataset.sub;
        $$('#cvSubs .subtab').forEach((x) => x.classList.toggle('active', x === c));
        loadColivingSub();
      });
    });
    loadColivingSub();
  }

  async function loadColivingSub() {
    const body = $('#cvBody');
    if (!body) return;
    const sub = state.colivingSub;
    if (sub === 'chores') return renderChores(body);
    if (sub === 'meals') return renderMeals(body);
    if (sub === 'grocery') return renderGrocery(body);
    if (sub === 'finances') return renderFinances(body);
    if (sub === 'polls') return renderPolls(body);
    if (sub === 'karma') return renderKarma(body);
  }

  /* ─── Offline local stores (API ishlamaganda ham to‘liq ishlaydi) ── */
  const LS_FIN = 'xd_finances_v1';
  const LS_POLL = 'xd_polls_v1';
  const LS_KARMA = 'xd_karma_v1';

  function lsGet(key) {
    try { return JSON.parse(localStorage.getItem(key) || 'null'); } catch { return null; }
  }
  function lsSet(key, val) {
    localStorage.setItem(key, JSON.stringify(val));
  }

  function defaultFinances(gc) {
    const items = [
      {
        id: 1, type: 'rent', title: 'Oylik ijara to‘lovi (Joriy oy)', amount_uzs: 4000000,
        paid_by: 'Uy egasiga', category: 'rent', due_date: 'Har oyning 5-sanasi', status: 'partially_paid',
        splits: [
          { name: 'Jasur', amount_uzs: 1000000, is_paid: true },
          { name: 'Azizbek', amount_uzs: 1000000, is_paid: true },
          { name: 'Bekzod', amount_uzs: 1000000, is_paid: false },
          { name: 'Sardor', amount_uzs: 1000000, is_paid: true },
        ], notes: 'Bekzod stipendiyasi tushishi bilan to‘laydi', created_at: new Date().toISOString(),
      },
      {
        id: 2, type: 'utility', title: 'Svet & Elektr energiyasi (Hisoblagich)', amount_uzs: 180000,
        paid_by: 'Jasur', category: 'electricity', due_date: '10-kungacha', status: 'partially_paid',
        splits: [
          { name: 'Jasur', amount_uzs: 45000, is_paid: true },
          { name: 'Azizbek', amount_uzs: 45000, is_paid: true },
          { name: 'Bekzod', amount_uzs: 45000, is_paid: false },
          { name: 'Sardor', amount_uzs: 45000, is_paid: false },
        ], notes: 'Jasur Click orqali to‘lab qo‘ydi', created_at: new Date().toISOString(),
      },
      {
        id: 3, type: 'utility', title: 'Optik Wi-Fi Internet (100 Mbps)', amount_uzs: 140000,
        paid_by: 'Sardor', category: 'internet', due_date: '1-kungacha', status: 'settled',
        splits: [
          { name: 'Jasur', amount_uzs: 35000, is_paid: true },
          { name: 'Azizbek', amount_uzs: 35000, is_paid: true },
          { name: 'Bekzod', amount_uzs: 35000, is_paid: true },
          { name: 'Sardor', amount_uzs: 35000, is_paid: true },
        ], notes: 'Hamma to‘liq hisob-kitob qildi', created_at: new Date().toISOString(),
      },
      {
        id: 4, type: 'expense_split', title: 'Katta bozorlik (Go‘sht, yog‘, guruch)', amount_uzs: 320000,
        paid_by: 'Azizbek', category: 'grocery_shared', due_date: 'Tezkor', status: 'partially_paid',
        splits: [
          { name: 'Jasur', amount_uzs: 80000, is_paid: true },
          { name: 'Azizbek', amount_uzs: 80000, is_paid: true },
          { name: 'Bekzod', amount_uzs: 80000, is_paid: false },
          { name: 'Sardor', amount_uzs: 80000, is_paid: true },
        ], notes: 'Qo‘yliq bozoridan', created_at: new Date().toISOString(),
      },
    ];
    return rebuildFinances({ ok: true, group_code: gc, all_items: items });
  }

  function rebuildFinances(cache) {
    const all = (cache.all_items || []).map((it) => ({ ...it, splits: (it.splits || []).map((s) => ({ ...s })) }));
    let totalSpend = 0, totalPending = 0, rentTotal = 0, utilTotal = 0, expTotal = 0;
    const debts = {};
    all.forEach((item) => {
      const amt = Number(item.amount_uzs || 0);
      totalSpend += amt;
      if (item.type === 'rent') rentTotal += amt;
      else if (item.type === 'utility') utilTotal += amt;
      else expTotal += amt;
      let paidSum = 0, pendingSum = 0;
      (item.splits || []).forEach((s) => {
        const sAmt = Number(s.amount_uzs || 0);
        if (s.is_paid) paidSum += sAmt;
        else {
          pendingSum += sAmt;
          totalPending += sAmt;
          const creditor = item.paid_by || '';
          const debtor = s.name || '';
          if (creditor && creditor !== 'Uy egasiga' && debtor && debtor !== creditor) {
            const key = `${debtor}->${creditor}`;
            if (!debts[key]) debts[key] = { debtor, creditor, amount_uzs: 0, reason: item.title || '' };
            debts[key].amount_uzs += sAmt;
          }
        }
      });
      item.paid_amount_uzs = paidSum;
      item.pending_amount_uzs = pendingSum;
      item.status = pendingSum === 0 ? 'settled' : (paidSum > 0 ? 'partially_paid' : 'pending');
    });
    return {
      ok: true,
      group_code: cache.group_code || 'home_default',
      summary: {
        total_spend_uzs: totalSpend,
        total_pending_uzs: totalPending,
        rent_total_uzs: rentTotal,
        utility_total_uzs: utilTotal,
        expense_total_uzs: expTotal,
      },
      debt_balances: Object.values(debts),
      rent_items: all.filter((x) => x.type === 'rent'),
      utility_items: all.filter((x) => x.type === 'utility'),
      expense_items: all.filter((x) => x.type === 'expense_split' || x.type === 'debt'),
      all_items: all,
    };
  }

  async function loadFinancesData(gc) {
    const res = await Api.finances(gc);
    if (res && res.ok) {
      lsSet(LS_FIN, res);
      return res;
    }
    let local = lsGet(LS_FIN);
    if (!local || !local.ok) {
      local = defaultFinances(gc);
      lsSet(LS_FIN, local);
    }
    return local;
  }

  function defaultPolls(gc) {
    return {
      ok: true,
      group_code: gc,
      active_count: 2,
      polls: [
        {
          id: 1, title: 'Kechasi 23:00 dan keyin mehmon chaqirmaslik qoidasi',
          description: 'Dars va imtihon mavsumida tinch uxlab dam olish uchun.',
          category: 'rules', status: 'passed', votes_yes: 3, votes_no: 1, votes_neutral: 0,
          total_votes: 4, yes_percent: 75, no_percent: 25, neutral_percent: 0,
          created_at: new Date().toISOString(),
        },
        {
          id: 2, title: 'Har yakshanba umumiy "Generalka" tozalik kuni',
          description: 'Yakshanba 10:00 da 1 soat chuqur tozalik.',
          category: 'cleaning', status: 'active', votes_yes: 2, votes_no: 0, votes_neutral: 1,
          total_votes: 3, yes_percent: 67, no_percent: 0, neutral_percent: 33,
          created_at: new Date().toISOString(),
        },
        {
          id: 3, title: 'Wi-Fi tezligini oshirish (100 Mbps)',
          description: 'Kishi boshiga oyiga ~12 000 so‘m qo‘shiladi.',
          category: 'general', status: 'active', votes_yes: 2, votes_no: 1, votes_neutral: 1,
          total_votes: 4, yes_percent: 50, no_percent: 25, neutral_percent: 25,
          created_at: new Date().toISOString(),
        },
      ],
    };
  }

  async function loadPollsData(gc) {
    const res = await Api.polls(gc);
    if (res && res.ok) {
      lsSet(LS_POLL, res);
      return res;
    }
    let local = lsGet(LS_POLL);
    if (!local || !local.ok) {
      local = defaultPolls(gc);
      lsSet(LS_POLL, local);
    }
    return local;
  }

  function defaultKarma(gc) {
    const badges = [
      { key: 'cleanliness_master', name: 'Tozalik ustasi', icon: '🧹', description: '' },
      { key: 'chef_pro', name: 'Mohir oshpaz', icon: '👨‍🍳', description: '' },
      { key: 'ontime_payer', name: 'Vaqtida to‘lovchi', icon: '⏱', description: '' },
      { key: 'quiet_peacekeeper', name: 'Tinchlik posboni', icon: '🤫', description: '' },
      { key: 'helpful_friend', name: 'Do‘stona xonadosh', icon: '🤝', description: '' },
      { key: 'wake_up_hero', name: 'Tonggi uyg‘otuvchi', icon: '⏰', description: '' },
    ];
    const history = [
      { id: 1, from_name: 'Azizbek', to_name: 'Jasur', badge_key: 'chef_pro', badge_name: 'Mohir oshpaz', points: 3, comment: 'Palov juda mazali chiqdi!', created_at: new Date().toISOString() },
      { id: 2, from_name: 'Jasur', to_name: 'Bekzod', badge_key: 'cleanliness_master', badge_name: 'Tozalik ustasi', points: 2, comment: 'Oshxonani chinnidek yuvdi', created_at: new Date().toISOString() },
      { id: 3, from_name: 'Sardor', to_name: 'Azizbek', badge_key: 'ontime_payer', badge_name: 'Vaqtida to‘lovchi', points: 3, comment: 'Wi-Fi pulini birinchi to‘ladi', created_at: new Date().toISOString() },
      { id: 4, from_name: 'Bekzod', to_name: 'Sardor', badge_key: 'quiet_peacekeeper', badge_name: 'Tinchlik posboni', points: 2, comment: 'Imtihon oldidan tinch muhit', created_at: new Date().toISOString() },
      { id: 5, from_name: 'Jasur', to_name: 'Azizbek', badge_key: 'helpful_friend', badge_name: 'Do‘stona xonadosh', points: 2, comment: 'Bozorlikda yordam berdi', created_at: new Date().toISOString() },
    ];
    return rebuildKarma({ ok: true, group_code: gc, available_badges: badges, roommates: ['Jasur', 'Azizbek', 'Bekzod', 'Sardor'], history });
  }

  function rebuildKarma(cache) {
    const roommates = cache.roommates || ['Jasur', 'Azizbek', 'Bekzod', 'Sardor'];
    const stats = {};
    roommates.forEach((n) => {
      stats[n] = { name: n, total_points: 0, badges_count: 0, badges_summary: {}, recent_praises: [] };
    });
    (cache.history || []).forEach((r) => {
      const to = r.to_name;
      if (!to) return;
      if (!stats[to]) stats[to] = { name: to, total_points: 0, badges_count: 0, badges_summary: {}, recent_praises: [] };
      stats[to].total_points += Number(r.points || 1);
      stats[to].badges_count += 1;
      const bk = r.badge_key || 'helpful_friend';
      if (!stats[to].badges_summary[bk]) stats[to].badges_summary[bk] = { key: bk, name: r.badge_name || '', count: 0 };
      stats[to].badges_summary[bk].count += 1;
      if (stats[to].recent_praises.length < 3) {
        stats[to].recent_praises.push({ from_name: r.from_name, badge_name: r.badge_name, comment: r.comment || '', created_at: r.created_at || '' });
      }
    });
    const leaderboard = Object.values(stats).map((m) => ({
      ...m,
      badges_summary: Object.values(m.badges_summary),
    })).sort((a, b) => b.total_points - a.total_points);
    return {
      ok: true,
      group_code: cache.group_code || 'home_default',
      available_badges: cache.available_badges || [],
      roommates,
      history: cache.history || [],
      leaderboard,
    };
  }

  async function loadKarmaData(gc) {
    const res = await Api.karma(gc);
    if (res && res.ok) {
      lsSet(LS_KARMA, res);
      return res;
    }
    let local = lsGet(LS_KARMA);
    if (!local || !local.ok) {
      local = defaultKarma(gc);
      lsSet(LS_KARMA, local);
    }
    return local;
  }

  /* ─── finances ────────────────────────────────────────── */
  async function renderFinances(body) {
    body.innerHTML = spinner();
    const gc = groupCode();
    const res = await loadFinancesData(gc);
    const sum = res.summary || {};
    const debts = res.debt_balances || [];
    const all = res.all_items || [
      ...(res.rent_items || []),
      ...(res.utility_items || []),
      ...(res.expense_items || []),
    ];
    const dueCount = all.filter((x) => x.status !== 'settled').length;
    const paidPct = sum.total_spend_uzs
      ? Math.round(((sum.total_spend_uzs - (sum.total_pending_uzs || 0)) / sum.total_spend_uzs) * 100)
      : 0;
    const filter = state.financeFilter || 'all';
    const filtered = all.filter((item) => {
      if (filter === 'due') return item.status !== 'settled';
      if (filter === 'rent') return item.type === 'rent';
      if (filter === 'utility') return item.type === 'utility';
      if (filter === 'expense') return item.type === 'expense_split' || item.type === 'debt';
      return true;
    });
    const typeIcon = (t) => (t === 'rent' ? '🏠' : t === 'utility' ? '⚡' : '🛍');
    const typeColor = (t) => (t === 'rent' ? '#6366f1' : t === 'utility' ? '#f59e0b' : '#10b981');

    let html = `
      <div class="panel" style="background:linear-gradient(135deg,#0f766e,#047857);color:#fff;padding:1rem">
        <div class="row" style="text-align:center;gap:.5rem">
          <div style="flex:1">
            <div style="opacity:.75;font-size:.75rem;font-weight:700">Jami</div>
            <div style="font-weight:900;font-size:1.05rem">${esc(money(sum.total_spend_uzs || 0))}</div>
          </div>
          <div style="width:1px;background:rgba(255,255,255,.2)"></div>
          <div style="flex:1">
            <div style="opacity:.75;font-size:.75rem;font-weight:700;color:#fca5a5">Qarz</div>
            <div style="font-weight:900;font-size:1.05rem;color:#fca5a5">${esc(money(sum.total_pending_uzs || 0))}</div>
          </div>
          <div style="width:1px;background:rgba(255,255,255,.2)"></div>
          <div style="flex:1">
            <div style="opacity:.75;font-size:.75rem;font-weight:700;color:#6ee7b7">Kutilmoqda</div>
            <div style="font-weight:900;font-size:1.05rem;color:#6ee7b7">${dueCount}</div>
          </div>
        </div>
        <div style="margin-top:.75rem;height:8px;background:rgba(255,255,255,.2);border-radius:6px;overflow:hidden">
          <div style="height:100%;width:${paidPct}%;background:#6ee7b7"></div>
        </div>
        <div style="margin-top:.35rem;font-size:.8rem;opacity:.8;text-align:center">${paidPct}% to‘langan</div>
      </div>`;

    if (debts.length) {
      html += `<div class="row" style="overflow-x:auto;gap:.5rem;margin-top:.75rem;padding-bottom:.25rem">`;
      debts.forEach((d) => {
        html += `<div class="panel" style="min-width:150px;padding:.75rem;border-color:rgba(245,158,11,.35);margin:0">
          <div class="row" style="gap:.35rem;align-items:center;font-weight:800;font-size:.85rem">
            <span>${esc((d.debtor || '?')[0])}</span>
            <span style="color:#f59e0b">→</span>
            <span style="color:var(--em2)">${esc((d.creditor || '?')[0])}</span>
          </div>
          <div style="font-weight:900;color:#d97706;margin-top:.4rem">${esc(money(d.amount_uzs))}</div>
        </div>`;
      });
      html += `</div>`;
    }

    html += `<div class="row" style="gap:.4rem;overflow-x:auto;margin-top:.75rem;flex-wrap:nowrap">
      ${[['all', 'Hammasi', all.length], ['due', 'Qarzda', dueCount], ['rent', 'Ijara', (res.rent_items || []).length], ['utility', 'Kommunal', (res.utility_items || []).length], ['expense', 'Xarid', (res.expense_items || []).length]]
        .map(([k, l, c]) => `<button type="button" class="chip fn-filter${filter === k ? ' active' : ''}" data-f="${k}">${esc(l)} · ${c}</button>`).join('')}
    </div>
    <div class="row between" style="margin-top:.75rem">
      <strong style="font-size:.95rem">${filtered.length} ta</strong>
      <button type="button" class="btn btn-primary btn-sm" id="fnAdd">+ To‘lov</button>
    </div>
    <div class="stack" style="margin-top:.5rem">`;

    if (!filtered.length) {
      html += `<div class="empty" style="padding:2rem;text-align:center;opacity:.6">Bo‘sh</div>`;
    } else {
      filtered.forEach((item) => {
        const isSettled = item.status === 'settled';
        const paid = Number(item.paid_amount_uzs || 0);
        const total = Number(item.amount_uzs || 1);
        const pct = Math.round((paid / total) * 100);
        const unpaid = (item.splits || []).filter((s) => !s.is_paid).length;
        html += `<div class="panel stack" style="padding:.85rem">
          <div class="row between">
            <div class="row" style="gap:.6rem">
              <div style="width:40px;height:40px;border-radius:12px;background:${typeColor(item.type)}22;display:flex;align-items:center;justify-content:center;font-size:1.1rem">${typeIcon(item.type)}</div>
              <div>
                <strong style="display:block">${esc(item.title)}</strong>
                <span style="font-size:.8rem;font-weight:700;color:${isSettled ? 'var(--em2)' : '#d97706'}">${isSettled ? 'Yopildi' : unpaid + ' kishi qarzdor'}</span>
              </div>
            </div>
            <strong class="price">${esc(money(item.amount_uzs))}</strong>
          </div>
          <div style="height:6px;background:var(--bg2);border-radius:4px;overflow:hidden;margin-top:.55rem">
            <div style="height:100%;width:${pct}%;background:${typeColor(item.type)}"></div>
          </div>
          <div class="row wrap" style="gap:.35rem;margin-top:.55rem">
            ${(item.splits || []).map((s) => `
              <button type="button" class="chip fn-toggle${s.is_paid ? ' active' : ''}" data-fid="${item.id}" data-name="${esc(s.name)}" data-paid="${s.is_paid ? '1' : '0'}" style="font-size:.78rem">
                ${s.is_paid ? '✓' : '○'} ${esc(s.name)}
              </button>
            `).join('')}
          </div>
        </div>`;
      });
    }
    html += `</div>`;
    body.innerHTML = html;

    $$('.fn-filter', body).forEach((btn) => {
      btn.addEventListener('click', () => {
        state.financeFilter = btn.dataset.f;
        renderFinances(body);
      });
    });
    $('#fnAdd').addEventListener('click', () => showAddFinanceModal(body, gc));
    $$('.fn-toggle', body).forEach((btn) => {
      btn.addEventListener('click', async () => {
        const fid = Number(btn.dataset.fid);
        const memberName = btn.dataset.name;
        const currentPaid = btn.dataset.paid === '1';
        const r = await Api.financeAction({
          action: 'toggle_member_paid',
          finance_id: fid,
          member_name: memberName,
          is_paid: !currentPaid ? 1 : 0,
          group_code: gc,
        });
        if (!(r && r.ok)) {
          let local = lsGet(LS_FIN) || defaultFinances(gc);
          const items = (local.all_items || []).map((it) => ({ ...it, splits: (it.splits || []).map((s) => ({ ...s })) }));
          items.forEach((it) => {
            if (Number(it.id) !== fid) return;
            (it.splits || []).forEach((s) => {
              if ((s.name || '').toLowerCase() === (memberName || '').toLowerCase()) s.is_paid = !currentPaid;
            });
          });
          local = rebuildFinances({ ...local, all_items: items });
          lsSet(LS_FIN, local);
        }
        toast(currentPaid ? `${memberName} — bekor` : `${memberName} to‘ladi ✓`);
        renderFinances(body);
      });
    });
  }

  function showAddFinanceModal(body, gc) {
    const html = `
      <div class="sheet stack">
        <h3 class="section-title" style="margin:0">Yangi to‘lov</h3>
        <div class="row" style="gap:.4rem">
          <button type="button" class="chip fn-type active" data-t="utility">⚡ Kommunal</button>
          <button type="button" class="chip fn-type" data-t="rent">🏠 Ijara</button>
          <button type="button" class="chip fn-type" data-t="expense_split">🛍 Xarid</button>
        </div>
        <div class="row wrap" id="fnPresets" style="gap:.35rem"></div>
        <div class="field"><label>Nomi</label><input id="fnTitle" placeholder="Svet" /></div>
        <div class="field"><label>Summa</label><input id="fnAmount" type="number" placeholder="180000" /></div>
        <div class="field"><label>Kim to‘ladi?</label>
          <select id="fnPaidBy">
            <option>Jasur</option><option>Azizbek</option><option>Bekzod</option><option>Sardor</option>
            <option value="Uy egasiga">Uy egasi</option>
          </select>
        </div>
        <div class="row between">
          <button type="button" class="btn btn-ghost" id="fnCancel">${esc(I18n.t('cancel'))}</button>
          <button type="button" class="btn btn-primary" id="fnSave">Saqlash</button>
        </div>
      </div>`;
    openModal(html);
    let type = 'utility';
    const presets = {
      utility: [['Svet', '180000'], ['Gaz', '90000'], ['Suv', '60000'], ['Wi-Fi', '140000']],
      rent: [['Oylik ijara', '4000000']],
      expense_split: [['Bozorlik', '320000'], ['Uy jihozlari', '150000']],
    };
    const paintPresets = () => {
      const box = $('#fnPresets');
      box.innerHTML = (presets[type] || []).map(([t, a]) =>
        `<button type="button" class="chip fn-preset" data-title="${esc(t)}" data-amt="${a}">${esc(t)}</button>`
      ).join('');
      $$('.fn-preset', box).forEach((b) => b.addEventListener('click', () => {
        $('#fnTitle').value = b.dataset.title;
        $('#fnAmount').value = b.dataset.amt;
      }));
    };
    paintPresets();
    $$('.fn-type').forEach((b) => b.addEventListener('click', () => {
      type = b.dataset.t;
      $$('.fn-type').forEach((x) => x.classList.toggle('active', x === b));
      paintPresets();
    }));
    $('#fnCancel').addEventListener('click', closeModal);
    $('#fnSave').addEventListener('click', async () => {
      const title = $('#fnTitle').value.trim();
      const amount = Number($('#fnAmount').value || 0);
      const paidBy = $('#fnPaidBy').value.trim() || 'Jasur';
      if (!title || amount <= 0) { toast('Nom va summani kiriting'); return; }
      const r = await Api.financeAction({
        action: 'add_expense', type, title, amount_uzs: amount, paid_by: paidBy, group_code: gc,
      });
      if (!(r && r.ok)) {
        let local = lsGet(LS_FIN) || defaultFinances(gc);
        const members = ['Jasur', 'Azizbek', 'Bekzod', 'Sardor'];
        const per = Math.round(amount / members.length);
        const item = {
          id: Date.now(), type, title, amount_uzs: amount, paid_by: paidBy, category: 'general',
          due_date: 'Joriy oy', status: 'pending',
          splits: members.map((m) => ({
            name: m, amount_uzs: per,
            is_paid: m === paidBy && (type === 'expense_split' || type === 'utility'),
          })),
          notes: '', created_at: new Date().toISOString(),
        };
        local = rebuildFinances({ ...local, all_items: [item, ...(local.all_items || [])] });
        lsSet(LS_FIN, local);
      }
      toast('To‘lov qo‘shildi!');
      closeModal();
      renderFinances(body);
    });
  }

  /* ─── polls ────────────────────────────────────────────── */
  async function renderPolls(body) {
    body.innerHTML = spinner();
    const gc = groupCode();
    const res = await loadPollsData(gc);
    const polls = res.polls || [];

    let html = `
      <div class="panel stack" style="background:linear-gradient(135deg, #4338ca, #3730a3);color:#fff">
        <div class="row"><span style="font-size:1.3rem">🔒</span>
          <div>
            <strong style="font-size:1.1rem;display:block">100% Anonim Ovoz Berish</strong>
            <p style="opacity:.8;margin:.2rem 0 0;font-size:.85rem">Xonadondagi har qanday masala va qoidani tortinmasdan o‘rtaga tashlang</p>
          </div>
        </div>
      </div>
      <div class="row between" style="margin-top:.75rem">
        <h3 class="section-title" style="margin:0">Xonadon Masalalari (${polls.length})</h3>
        <button type="button" class="btn btn-ghost btn-sm" id="plAdd">+ Masala tashlash</button>
      </div>
      <div class="stack" style="margin-top:.5rem">`;

    if (!polls.length) {
      html += emptyState('Hozircha o‘rtaga tashlangan masalalar yo‘q', '🗳');
    } else {
      polls.forEach((p) => {
        const isActive = p.status === 'active';
        const isPassed = p.status === 'passed';
        const statusLabel = isPassed ? '✅ Qabul qilindi' : (p.status === 'rejected' ? '❌ Rad etildi' : '🗳 Ovoz berish faol');
        const badgeBg = isPassed ? 'rgba(5,150,105,0.15)' : (p.status === 'rejected' ? 'rgba(220,38,38,0.15)' : 'rgba(99,102,241,0.15)');
        const badgeColor = isPassed ? '#059669' : (p.status === 'rejected' ? '#dc2626' : '#4f46e5');

        html += `<div class="panel stack" style="padding:.85rem;border-color:${isActive ? 'rgba(99,102,241,0.5)' : 'var(--border)'}">
          <div class="row between">
            <span style="background:${badgeBg};color:${badgeColor};font-size:.75rem;font-weight:800;padding:.2rem .5rem;border-radius:6px">${esc(statusLabel)}</span>
            <span class="muted" style="font-size:.8rem">${esc(p.total_votes)} ta ovoz</span>
          </div>
          <strong style="font-size:1rem;margin-top:.2rem">${esc(p.title)}</strong>
          ${p.description ? `<p class="muted" style="margin:0;font-size:.85rem">${esc(p.description)}</p>` : ''}
          
          <div style="height:8px;border-radius:4px;overflow:hidden;display:flex;background:#e2e8f0;margin-top:.4rem">
            ${p.yes_percent > 0 ? `<div style="flex:${p.yes_percent};background:#10b981"></div>` : ''}
            ${p.no_percent > 0 ? `<div style="flex:${p.no_percent};background:#ef4444"></div>` : ''}
            ${p.neutral_percent > 0 ? `<div style="flex:${p.neutral_percent};background:#94a3b8"></div>` : ''}
          </div>
          <div class="row between" style="font-size:.8rem;font-weight:700">
            <span style="color:#059669">👍 Ha: ${p.votes_yes} (${p.yes_percent}%)</span>
            <span style="color:#dc2626">👎 Yo‘q: ${p.votes_no} (${p.no_percent}%)</span>
            <span class="muted">🤷‍♂️ Betaraf: ${p.votes_neutral}</span>
          </div>
          ${isActive ? `
            <div class="row" style="gap:.5rem;margin-top:.5rem;border-top:1px solid var(--border);padding-top:.5rem">
              <button type="button" class="btn btn-ghost btn-sm pl-vote" data-pid="${p.id}" data-vote="yes" style="flex:1;background:rgba(16,185,129,0.1);color:#047857;font-weight:800">👍 Rozi</button>
              <button type="button" class="btn btn-ghost btn-sm pl-vote" data-pid="${p.id}" data-vote="no" style="flex:1;background:rgba(239,68,68,0.1);color:#b91c1c;font-weight:800">👎 Qarshi</button>
              <button type="button" class="btn btn-ghost btn-sm pl-vote" data-pid="${p.id}" data-vote="neutral" style="flex:1;background:var(--bg2)">🤷‍♂️ Betaraf</button>
            </div>
          ` : ''}
        </div>`;
      });
    }
    html += `</div>`;
    body.innerHTML = html;

    $('#plAdd').addEventListener('click', () => showAddPollModal(body, gc));

    $$('.pl-vote', body).forEach((btn) => {
      btn.addEventListener('click', async () => {
        const pollId = Number(btn.dataset.pid);
        const vote = btn.dataset.vote;
        const r = await Api.pollAction({
          action: 'vote',
          poll_id: pollId,
          vote,
          group_code: gc,
        });
        if (r && r.ok) {
          toast(r.message || 'Ovozingiz qabul qilindi!');
          renderPolls(body);
          return;
        }
        let local = lsGet(LS_POLL) || defaultPolls(gc);
        const pollsList = (local.polls || []).map((p) => ({ ...p }));
        const p = pollsList.find((x) => Number(x.id) === pollId);
        if (!p || p.status !== 'active') {
          toast('Bu masala bo‘yicha ovoz berish yakunlangan');
          return;
        }
        if (vote === 'yes') p.votes_yes = Number(p.votes_yes || 0) + 1;
        else if (vote === 'no') p.votes_no = Number(p.votes_no || 0) + 1;
        else p.votes_neutral = Number(p.votes_neutral || 0) + 1;
        const total = Number(p.votes_yes) + Number(p.votes_no) + Number(p.votes_neutral);
        p.total_votes = total;
        p.yes_percent = total ? Math.round((p.votes_yes / total) * 100) : 0;
        p.no_percent = total ? Math.round((p.votes_no / total) * 100) : 0;
        p.neutral_percent = total ? Math.round((p.votes_neutral / total) * 100) : 0;
        if (total >= 3) {
          if (p.votes_yes > p.votes_no) p.status = 'passed';
          else if (p.votes_no > p.votes_yes) p.status = 'rejected';
        }
        local.polls = pollsList;
        local.active_count = pollsList.filter((x) => x.status === 'active').length;
        lsSet(LS_POLL, local);
        toast('Ovozingiz anonim tarzda qabul qilindi!');
        renderPolls(body);
      });
    });
  }

  function showAddPollModal(body, gc) {
    const html = `
      <div class="modal" id="plModal">
        <div class="modal-card stack">
          <h3 class="section-title">🔒 Anonim Masala Tashlash</h3>
          <div class="field">
            <label>Kategoriya</label>
            <select id="plCat">
              <option value="rules">📋 Xonadon qoidasi</option>
              <option value="cleaning">🧹 Tozalik va tartib</option>
              <option value="shopping">🛒 Xaridlar va byudjet</option>
              <option value="guests">👥 Mehmonlar tartibi</option>
              <option value="general">💡 Umumiy taklif</option>
            </select>
          </div>
          <div class="field">
            <label>Masala / Taklif sarlavhasi</label>
            <input id="plTitle" placeholder="e.g. 23:00 dan keyin shovqin qilmaslik" />
          </div>
          <div class="field">
            <label>Batafsil tushuntirish</label>
            <textarea id="plDesc" rows="3" placeholder="Nega bu taklif kerakligini tushuntiring..."></textarea>
          </div>
          <div class="row between">
            <button type="button" class="btn btn-ghost" id="plCancel">${esc(I18n.t('cancel'))}</button>
            <button type="button" class="btn btn-primary" id="plSave">O‘rtaga tashlash</button>
          </div>
        </div>
      </div>`;
    openModal(html);
    $('#plCancel').addEventListener('click', closeModal);
    $('#plSave').addEventListener('click', async () => {
      const category = $('#plCat').value;
      const title = $('#plTitle').value.trim();
      const description = $('#plDesc').value.trim();
      if (!title) {
        toast('Sarlavhani kiriting');
        return;
      }
      const r = await Api.pollAction({
        action: 'create_poll',
        category,
        title,
        description,
        group_code: gc,
      });
      if (r && r.ok) {
        toast('Anonim masala muvaffaqiyatli tashlandi!');
        closeModal();
        renderPolls(body);
        return;
      }
      let local = lsGet(LS_POLL) || defaultPolls(gc);
      const pollsList = [...(local.polls || [])];
      pollsList.unshift({
        id: Date.now(),
        title,
        description,
        category,
        status: 'active',
        votes_yes: 0,
        votes_no: 0,
        votes_neutral: 0,
        total_votes: 0,
        yes_percent: 0,
        no_percent: 0,
        neutral_percent: 0,
        created_at: new Date().toISOString(),
      });
      local.polls = pollsList;
      local.active_count = pollsList.filter((x) => x.status === 'active').length;
      lsSet(LS_POLL, local);
      toast('Anonim masala muvaffaqiyatli tashlandi!');
      closeModal();
      renderPolls(body);
    });
  }

  /* ─── karma ────────────────────────────────────────────── */
  async function renderKarma(body) {
    body.innerHTML = spinner();
    const gc = groupCode();
    const res = await loadKarmaData(gc);
    const leaderboard = res.leaderboard || [];
    const badges = res.available_badges || [];
    const roommates = res.roommates || ['Jasur', 'Azizbek', 'Bekzod', 'Sardor'];

    let html = `
      <div class="panel stack" style="background:linear-gradient(135deg, #d97706, #b45309);color:#fff">
        <div class="row"><span style="font-size:1.3rem">⭐</span>
          <div>
            <strong style="font-size:1.1rem;display:block">Xonadoshlar Obro‘ Reytingi</strong>
            <p style="opacity:.85;margin:.2rem 0 0;font-size:.85rem">Tozalik, mazali taom, o‘z vaqtida to‘lov uchun xonadoshlaringizga nishon va obro‘ bering!</p>
          </div>
        </div>
      </div>
      <div class="row between" style="margin-top:.75rem">
        <h3 class="section-title" style="margin:0">Yetakchilar doskasi (Leaderboard)</h3>
        <button type="button" class="btn btn-ghost btn-sm" id="kmAdd">+ Obro‘ berish</button>
      </div>
      <div class="stack" style="margin-top:.5rem">`;

    leaderboard.forEach((m, idx) => {
      const medal = idx === 0 ? '🥇' : (idx === 1 ? '🥈' : (idx === 2 ? '🥉' : `${idx + 1}`));
      html += `<div class="panel stack" style="padding:.85rem;border-color:${idx === 0 ? '#f59e0b' : 'var(--border)'}">
        <div class="row between">
          <div class="row" style="gap:.6rem">
            <span style="font-size:1.3rem">${medal}</span>
            <div>
              <strong style="font-size:1.05rem">${esc(m.name)}</strong>
              <p class="muted" style="margin:0;font-size:.8rem">${esc(m.badges_count)} ta nishon olgan</p>
            </div>
          </div>
          <span style="background:rgba(245,158,11,0.15);color:#d97706;padding:.3rem .6rem;border-radius:12px;font-weight:900;font-size:.95rem">
            ⭐ ${esc(m.total_points)} ball
          </span>
        </div>
        ${(m.badges_summary || []).length ? `
          <div class="row wrap" style="gap:.4rem;margin-top:.4rem">
            ${m.badges_summary.map((b) => `<span style="background:var(--bg2);padding:.2rem .5rem;border-radius:6px;font-size:.78rem;font-weight:700">${esc(b.name)} (${b.count})</span>`).join('')}
          </div>
        ` : ''}
        ${(m.recent_praises || []).length ? `
          <p class="muted" style="margin:.3rem 0 0;font-size:.8rem;font-style:italic">
            💬 "${esc(m.recent_praises[0].comment)}" — ${esc(m.recent_praises[0].from_name)}
          </p>
        ` : ''}
      </div>`;
    });
    html += `</div>`;
    body.innerHTML = html;

    $('#kmAdd').addEventListener('click', () => showAddKarmaModal(body, gc, roommates, badges));
  }

  function showAddKarmaModal(body, gc, roommates, badges) {
    const html = `
      <div class="modal" id="kmModal">
        <div class="modal-card stack">
          <h3 class="section-title">⭐ Xonadoshga Obro‘ Berish</h3>
          <div class="field">
            <label>Kimga obro‘ berasiz?</label>
            <select id="kmTo">
              ${roommates.map((r) => `<option value="${esc(r)}">${esc(r)}</option>`).join('')}
            </select>
          </div>
          <div class="field">
            <label>Qanday nishon berasiz?</label>
            <select id="kmBadge">
              ${badges.map((b) => `<option value="${esc(b.key)}" data-name="${esc(b.name)}">${esc(b.icon)} ${esc(b.name)}</option>`).join('')}
            </select>
          </div>
          <div class="field">
            <label>Ball miqdori</label>
            <select id="kmPoints">
              <option value="1">+1 ball</option>
              <option value="2" selected>+2 ball</option>
              <option value="3">+3 ball</option>
              <option value="5">+5 ball</option>
            </select>
          </div>
          <div class="field">
            <label>Minnatdorchilik / Izoh</label>
            <input id="kmComment" placeholder="Nima uchun minnatdorsiz?..." />
          </div>
          <div class="row between">
            <button type="button" class="btn btn-ghost" id="kmCancel">${esc(I18n.t('cancel'))}</button>
            <button type="button" class="btn btn-primary" id="kmSave">Topshirish</button>
          </div>
        </div>
      </div>`;
    openModal(html);
    $('#kmCancel').addEventListener('click', closeModal);
    $('#kmSave').addEventListener('click', async () => {
      const toName = $('#kmTo').value;
      const bSel = $('#kmBadge');
      const badgeKey = bSel.value;
      const badgeName = bSel.options[bSel.selectedIndex].dataset.name || badgeKey;
      const points = Number($('#kmPoints').value || 1);
      const comment = $('#kmComment').value.trim();

      const r = await Api.karmaAction({
        action: 'give_karma',
        to_name: toName,
        from_name: 'Xonadosh',
        badge_key: badgeKey,
        badge_name: badgeName,
        points,
        comment,
        group_code: gc,
      });
      if (r && r.ok) {
        toast(r.message || 'Obro‘ topshirildi!');
        closeModal();
        renderKarma(body);
        return;
      }
      let local = lsGet(LS_KARMA) || defaultKarma(gc);
      const history = [...(local.history || [])];
      history.unshift({
        id: Date.now(),
        from_name: 'Xonadosh',
        to_name: toName,
        badge_key: badgeKey,
        badge_name: badgeName,
        points,
        comment,
        created_at: new Date().toISOString(),
      });
      const rms = [...(local.roommates || [])];
      if (!rms.includes(toName)) rms.push(toName);
      local = rebuildKarma({ ...local, roommates: rms, history });
      lsSet(LS_KARMA, local);
      toast(`🎉 ${toName}ga "${badgeName}" nishoni berildi!`);
      closeModal();
      renderKarma(body);
    });
  }

  async function renderChores(body) {
    body.innerHTML = spinner();
    const gc = groupCode();
    const res = await Api.chores(gc);
    if (!res.ok) {
      body.innerHTML = errBox(res.error, 'chRetry');
      const b = $('#chRetry');
      if (b) b.addEventListener('click', () => renderChores(body));
      return;
    }
    const chores = res.all_chores || [];
    const todayDuties = res.today_duties || [];
    const todayDay = res.today_day || '';
    const byDay = {};
    DAYS_UZ.forEach((d) => { byDay[d] = []; });
    chores.forEach((c) => {
      const d = c.day_of_week || 'dushanba';
      if (!byDay[d]) byDay[d] = [];
      byDay[d].push(c);
    });

    let html = `
      <div class="duty-banner">
        <div class="row"><span style="font-size:1.2rem">📅</span>
          <strong>${esc(I18n.t('todayDuties'))}: ${esc(DAY_LABEL[todayDay] || todayDay)}</strong></div>
        ${todayDuties.length
          ? todayDuties.map((c) => `
            <div class="duty-item">
              <span>${esc(c.title)}</span>
              <span class="duty-who">${esc(c.assigned_name || '—')}</span>
            </div>`).join('')
          : `<p style="opacity:.8;margin:.5rem 0 0;font-size:.9rem">${esc(I18n.t('noDutyToday'))}</p>`}
      </div>
      <div class="row between">
        <h3 class="section-title" style="margin:0">${esc(I18n.t('weeklyChores'))}</h3>
        <button type="button" class="btn btn-ghost btn-sm" id="chAdd">+ ${esc(I18n.t('addChore'))}</button>
      </div>`;

    DAYS_UZ.forEach((day) => {
      const list = byDay[day] || [];
      if (!list.length) return;
      const isToday = day === todayDay;
      html += `<div class="panel stack${isToday ? ' day-today' : ''}" style="padding:.75rem">
        <h3 class="section-title" style="font-size:.95rem;margin:0;${isToday ? 'color:var(--em2)' : ''}">${esc(DAY_LABEL[day])}</h3>`;
      list.forEach((c) => {
        html += `<div class="check${c.is_completed ? ' done' : ''}" data-chore="${esc(c.id)}">
          <input type="checkbox" class="ch-toggle" data-id="${esc(c.id)}" ${c.is_completed ? 'checked' : ''} />
          <div style="flex:1">
            <div class="title"><strong>${esc(c.title)}</strong></div>
            <p class="muted" style="margin:0;font-size:.8rem">${esc(c.assigned_name || '—')} · ${esc(c.chore_type || '')}</p>
          </div>
          <button type="button" class="btn btn-ghost btn-sm ch-assign" data-id="${esc(c.id)}">${esc(I18n.t('assign'))}</button>
        </div>`;
      });
      html += `</div>`;
    });
    if (!chores.length) html += emptyState('Navbatchilik yo‘q', '✓');
    body.innerHTML = html;

    $('#chAdd').addEventListener('click', () => showAddChoreSheet(body, gc));

    $$('.ch-toggle', body).forEach((inp) => {
      inp.addEventListener('change', async () => {
        const r = await Api.choreAction({
          action: 'toggle_done',
          chore_id: Number(inp.dataset.id),
          is_completed: inp.checked ? 1 : 0,
          group_code: gc,
        });
        if (!r.ok) toast(r.error || 'Xato');
        else toast(I18n.t('done'));
        renderChores(body);
      });
    });
    $$('.ch-assign', body).forEach((btn) => {
      btn.addEventListener('click', () => {
        const name = prompt(I18n.t('assign') + ' — ism:');
        if (name == null) return;
        Api.choreAction({
          action: 'assign',
          chore_id: Number(btn.dataset.id),
          assigned_name: name.trim(),
          group_code: gc,
        }).then((r) => {
          if (!r.ok) toast(r.error || 'Xato');
          else { toast(I18n.t('done')); renderChores(body); }
        });
      });
    });
  }

  function showAddChoreSheet(body, gc) {
    openSheet(`
      <div class="handle"></div>
      <h3 class="section-title">${esc(I18n.t('addChore'))}</h3>
      <form id="chForm" class="stack">
        <div class="field"><label>${esc(I18n.t('title'))}</label><input name="title" required /></div>
        <div class="field"><label>Kun</label>
          <select name="day_of_week">
            ${DAYS_UZ.map((d) => `<option value="${d}">${esc(DAY_LABEL[d])}</option>`).join('')}
          </select></div>
        <div class="field"><label>${esc(I18n.t('assign'))}</label><input name="assigned_name" placeholder="Ism" /></div>
        <div class="field"><label>Tur</label>
          <select name="chore_type">
            <option value="cleaning">cleaning</option>
            <option value="cooking">cooking</option>
            <option value="trash">trash</option>
            <option value="shopping">shopping</option>
            <option value="other">other</option>
          </select></div>
        <button class="btn btn-primary btn-block" type="submit">${esc(I18n.t('save'))}</button>
        <button type="button" class="btn btn-ghost btn-block" id="chCancel">${esc(I18n.t('cancel'))}</button>
      </form>`);
    $('#chCancel').addEventListener('click', closeModal);
    $('#chForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const fd = new FormData(e.target);
      const r = await Api.choreAction({
        action: 'add',
        title: String(fd.get('title') || '').trim(),
        day_of_week: String(fd.get('day_of_week') || 'dushanba'),
        assigned_name: String(fd.get('assigned_name') || '').trim(),
        chore_type: String(fd.get('chore_type') || 'other'),
        group_code: gc,
      });
      if (!r.ok) { toast(r.error || 'Xato'); return; }
      toast(I18n.t('done'));
      closeModal();
      renderChores(body);
    });
  }

  async function renderMeals(body) {
    body.innerHTML = spinner();
    const gc = groupCode();
    const res = await Api.recipes({ group_code: gc });
    if (!res.ok) {
      body.innerHTML = errBox(res.error);
      return;
    }
    const recipes = res.recipes || [];
    const grouped = res.weekly_grouped || [];
    const flat = res.weekly_meal_plan || [];

    // Build day → meals map
    const byDay = {};
    DAYS_UZ.forEach((d) => { byDay[d] = []; });
    if (grouped.length) {
      grouped.forEach((day) => {
        const key = day.day_of_week;
        byDay[key] = day.meals || [];
      });
    } else {
      flat.forEach((m) => {
        const key = m.day_of_week || 'dushanba';
        if (!byDay[key]) byDay[key] = [];
        byDay[key].push(m);
      });
    }

    let html = `
      <div class="meal-info-banner">
        <strong>${esc(I18n.t('mealPlan'))}</strong>
        <div class="pill-row" style="margin-top:.5rem">
          <span class="chip" style="background:#fef3c7">🌅 ${esc(I18n.t('breakfast'))}</span>
          <span class="chip" style="background:#dbeafe">🌤 ${esc(I18n.t('lunch'))}</span>
          <span class="chip" style="background:#ede9fe">🌙 ${esc(I18n.t('dinner'))}</span>
        </div>
      </div>
      <div class="row between">
        <h3 class="section-title" style="margin:0">${esc(I18n.t('mealPlan'))}</h3>
        <button type="button" class="btn btn-ghost btn-sm" id="rcAddTop">+ ${esc(I18n.t('addRecipe'))}</button>
      </div>
      <div class="stack" id="mealAccordions">`;

    DAYS_UZ.forEach((day, di) => {
      let meals = byDay[day] || [];
      meals = meals.slice().sort((a, b) => MEAL_ORDER.indexOf(a.meal_time) - MEAL_ORDER.indexOf(b.meal_time));
      // Ensure 3 slots
      const slots = MEAL_ORDER.map((mt) => {
        const found = meals.find((m) => m.meal_time === mt);
        return found || { meal_time: mt, meal_time_label: I18n.t(mt === 'breakfast' ? 'breakfast' : mt === 'lunch' ? 'lunch' : 'dinner'), recipe_name: '—', cook_name: '' };
      });
      const cals = slots.reduce((s, m) => s + (Number(m.calories_kcal) || 0), 0);
      html += `
        <details class="meal-day"${di === 0 ? ' open' : ''}>
          <summary>
            <strong>${esc(DAY_LABEL[day])}</strong>
            ${cals ? `<span class="muted" style="font-size:.8rem">${esc(cals)} kkal</span>` : ''}
          </summary>
          <div class="stack" style="padding:.5rem 0">
            ${slots.map((m) => `
              <div class="meal-slot card" style="cursor:default" data-day="${esc(day)}" data-meal="${esc(m.meal_time)}">
                <div class="row between">
                  <div>
                    <strong>${esc(m.meal_time_label || m.meal_time)}</strong>
                    <p style="margin:.2rem 0 0">${esc(m.recipe_name || '—')}</p>
                    <p class="muted" style="margin:0;font-size:.8rem">
                      ${m.cook_name ? esc(m.cook_name) + ' · ' : ''}
                      ${m.prep_schedule || m.eating_schedule || ''}
                      ${m.bread_count != null ? ' · 🍞 ' + esc(m.bread_count) : ''}
                      ${m.tea_type ? ' · 🍵 ' + esc(m.tea_type) : ''}
                      ${m.calories_kcal ? ' · ' + esc(m.calories_kcal) + ' kkal' : ''}
                    </p>
                  </div>
                  <button type="button" class="btn btn-ghost btn-sm meal-swap" data-day="${esc(day)}" data-meal="${esc(m.meal_time)}" data-cook="${esc(m.cook_name || '')}">${esc(I18n.t('swapRecipe'))}</button>
                </div>
              </div>`).join('')}
          </div>
        </details>`;
    });

    html += `</div>
      <h3 class="section-title">${esc(I18n.t('recipes'))} (${recipes.length})</h3>
      <div class="recipe-grid">
        ${recipes.map((r) => `
          <article class="card recipe-card" data-id="${esc(r.id)}">
            <div class="recipe-thumb">${r.image_url ? `<img src="${esc(r.image_url)}" alt="" loading="lazy" />` : '🍽'}</div>
            <h3>${esc(r.name_uz)}</h3>
            <p class="muted" style="margin:0;font-size:.8rem">${esc(r.prep_time_min)} min · ${esc(r.cost_level || '')}</p>
          </article>`).join('') || emptyState(I18n.t('recipes'))}
      </div>`;

    body.innerHTML = html;

    $$('.meal-swap', body).forEach((btn) => {
      btn.addEventListener('click', () => {
        showRecipePicker(body, {
          day: btn.dataset.day,
          meal: btn.dataset.meal,
          cook: btn.dataset.cook,
          recipes,
          gc,
        });
      });
    });

    $$('.recipe-card', body).forEach((el) => {
      el.addEventListener('click', () => {
        const r = recipes.find((x) => String(x.id) === el.dataset.id);
        if (r) showRecipeDetail(r);
      });
    });

    $('#rcAddTop').addEventListener('click', () => showCreateRecipe(body));
  }

  function showRecipePicker(body, { day, meal, cook, recipes, gc }) {
    openSheet(`
      <div class="handle"></div>
      <h3 class="section-title">${esc(I18n.t('pickRecipe'))}</h3>
      <p class="muted">${esc(DAY_LABEL[day] || day)} · ${esc(meal)}</p>
      <div class="stack" id="rpList">
        ${recipes.map((r) => `
          <button type="button" class="card rp-item" data-id="${esc(r.id)}" style="text-align:left;width:100%">
            <strong>${esc(r.name_uz)}</strong>
            <p class="muted" style="margin:.2rem 0 0;font-size:.8rem">${esc(r.prep_time_min)} min · ${esc(r.category || '')}</p>
          </button>`).join('') || emptyState(I18n.t('recipes'))}
      </div>
      <button type="button" class="btn btn-ghost btn-block" id="rpClose">${esc(I18n.t('cancel'))}</button>`);
    $('#rpClose').addEventListener('click', closeModal);
    $$('.rp-item').forEach((el) => {
      el.addEventListener('click', async () => {
        const r = recipes.find((x) => String(x.id) === el.dataset.id);
        if (!r) return;
        const res = await Api.recipeAction({
          action: 'set_plan',
          day_of_week: day,
          meal_time: meal,
          recipe_id: r.id,
          recipe_name: r.name_uz,
          cook_name: cook || 'Xonadosh',
          group_code: gc,
        });
        if (!res.ok) { toast(res.error || 'Xato'); return; }
        toast(I18n.t('done'));
        closeModal();
        renderMeals(body);
      });
    });
  }

  function showRecipeDetail(r) {
    const ings = (r.ingredients || []).map((i) => {
      if (typeof i === 'string') return i;
      return `${i.name || i.key || ''} ${i.qty_per_person != null ? '(' + i.qty_per_person + ' ' + (i.unit || '') + ')' : ''}`.trim();
    });
    openSheet(`
      <div class="handle"></div>
      <h3 class="section-title">${esc(r.name_uz)}</h3>
      <p class="muted">${esc(r.category)} · ${esc(r.prep_time_min)} min · ${esc(r.calories_kcal || '')} kkal</p>
      <p class="section-title" style="font-size:.9rem">Ingredients</p>
      <ul>${ings.map((i) => `<li>${esc(i)}</li>`).join('') || '<li>—</li>'}</ul>
      <p class="section-title" style="font-size:.9rem">Instructions</p>
      <p>${esc(r.instructions_uz || '')}</p>
      <button type="button" class="btn btn-ghost btn-block" id="rcClose">${esc(I18n.t('cancel'))}</button>`);
    $('#rcClose').addEventListener('click', closeModal);
  }

  function showCreateRecipe(body) {
    openSheet(`
      <div class="handle"></div>
      <h3 class="section-title">${esc(I18n.t('addRecipe'))}</h3>
      <form id="rcForm" class="stack">
        <div class="field"><label>Nomi</label><input name="name_uz" required /></div>
        <div class="field"><label>Kategoriya</label>
          <select name="category">
            <option>Nonushta</option><option>Tushlik</option><option selected>Kechki ovqat</option>
          </select></div>
        <div class="grid-2">
          <div class="field"><label>Vaqt (min)</label><input name="prep_time_min" type="number" value="30" /></div>
          <div class="field"><label>Narx</label>
            <select name="cost_level"><option value="budget">budget</option><option value="medium">medium</option><option value="premium">premium</option></select>
          </div>
        </div>
        <div class="field"><label>Ingredients (har qator)</label>
          <textarea name="ingredients_lines" placeholder="Go‘sht&#10;Piyoz&#10;Sabzi"></textarea></div>
        <div class="field"><label>Ko‘rsatmalar</label><textarea name="instructions_uz"></textarea></div>
        <button class="btn btn-primary btn-block" type="submit">${esc(I18n.t('save'))}</button>
        <button type="button" class="btn btn-ghost btn-block" id="rcCancel">${esc(I18n.t('cancel'))}</button>
      </form>`);
    $('#rcCancel').addEventListener('click', closeModal);
    $('#rcForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const fd = new FormData(e.target);
      const lines = String(fd.get('ingredients_lines') || '').split('\n').map((s) => s.trim()).filter(Boolean);
      const ingredients = lines.map((name) => ({
        name, key: name.toLowerCase().replace(/\s+/g, '_'), qty_per_person: 0.1, unit: 'kg',
      }));
      const r = await Api.recipeAction({
        action: 'create_recipe',
        name_uz: String(fd.get('name_uz') || '').trim(),
        category: String(fd.get('category') || 'Kechki ovqat'),
        prep_time_min: Number(fd.get('prep_time_min') || 30),
        cost_level: String(fd.get('cost_level') || 'budget'),
        ingredients,
        instructions_uz: String(fd.get('instructions_uz') || ''),
      });
      if (!r.ok) { toast(r.error || 'Xato'); return; }
      toast(I18n.t('done'));
      closeModal();
      renderMeals(body);
    });
  }

  async function renderGrocery(body) {
    body.innerHTML = `
      <div class="panel stack">
        <div class="row between" style="align-items:flex-end">
          <div class="field" style="flex:1">
            <label>${esc(I18n.t('roommates'))}</label>
            <div class="stepper">
              <button type="button" class="step-btn" id="grMinus">−</button>
              <input id="grCount" type="number" min="1" max="10" value="${esc(state.groceryRoommates)}" readonly />
              <button type="button" class="step-btn" id="grPlus">+</button>
            </div>
          </div>
          <div class="field" style="flex:1">
            <label>${esc(I18n.t('groupCode'))}</label>
            <input id="grCode" value="${esc(groupCode())}" />
          </div>
        </div>
      </div>
      <div id="grOut" class="stack" style="margin-top:.75rem">${spinner()}</div>`;

    const reload = async () => {
      const out = $('#grOut');
      if (!out) return;
      out.innerHTML = spinner();
      const roommates = Number($('#grCount').value || 4);
      state.groceryRoommates = roommates;
      const code = ($('#grCode').value || '').trim() || 'home_default';
      setGroupCode(code);
      const res = await Api.grocery({ group_code: code, roommates, days: 7 });
      if (!res.ok) {
        out.innerHTML = errBox(res.error);
        return;
      }
      const sum = res.summary || {};
      const items = res.grocery_list || [];
      const bread = sum.bread_breakdown || res.bread_breakdown || null;
      let html = `<div class="panel stack grocery-summary">
        <strong class="price" style="font-size:1.2rem">${esc(I18n.t('totalCost'))}: ${esc(money(sum.total_cost_uzs || 0))}</strong>
        <p class="muted" style="margin:0">${esc(I18n.t('perPerson'))}: ${esc(money(sum.per_person_uzs || 0))} · kunlik: ${esc(money(sum.per_person_daily_uzs || 0))}</p>
        ${sum.cheapest_market || sum.cheapest_source ? `<p class="muted" style="margin:0;font-size:.85rem">🏪 ${esc(sum.cheapest_market || sum.cheapest_source)}</p>` : ''}
        ${sum.shopping_day ? `<p class="muted" style="margin:0;font-size:.85rem">${esc(sum.shopping_day)}</p>` : ''}
      </div>`;
      if (bread) {
        const bux = bread.total_buxanka || bread.breakfast_lunch_buxanka || 0;
        const pat = bread.total_patir || bread.dinner_patir || 0;
        const cost = bread.weekly_total_bread_spend || 0;
        html += `<div class="panel" style="padding:.85rem 1rem;background:rgba(245,158,11,0.08);border-color:rgba(245,158,11,0.25)">
          <strong style="color:#d97706">🍞 ${esc(I18n.t('breadBreakdown'))}</strong>
          <p class="muted" style="margin:.3rem 0 0;font-size:.85rem">Qolipli buxanka: <strong>${esc(bux)}</strong> dona · Tandir patir: <strong>${esc(pat)}</strong> dona</p>
          <p style="margin:.25rem 0 0;font-size:.85rem;font-weight:700;color:#d97706">Haftalik non sarfi: ~${esc(money(cost))}</p>
        </div>`;
      }
      html += `<div class="stack">`;
      items.forEach((it, i) => {
        html += `<label class="check grocery-item" data-i="${i}">
          <input type="checkbox" class="gr-check" />
          <div style="flex:1">
            <div class="row between">
              <strong class="title">${esc(it.name_uz)}</strong>
              <span class="price">${esc(money(it.total_cost_uzs))}</span>
            </div>
            <p class="muted" style="margin:.25rem 0 0;font-size:.82rem">
              ${esc(it.qty_needed)} ${esc(it.unit)} · ${esc(it.cheapest_source || '')}
            </p>
            ${it.buying_tips ? `<p style="margin:.25rem 0 0;font-size:.8rem">💡 ${esc(it.buying_tips)}</p>` : ''}
          </div>
        </label>`;
      });
      html += `</div>`;
      out.innerHTML = html;
      $$('.gr-check', out).forEach((inp) => {
        inp.addEventListener('change', () => {
          const row = inp.closest('.grocery-item');
          if (row) row.classList.toggle('done', inp.checked);
        });
      });
    };

    $('#grMinus').addEventListener('click', () => {
      const inp = $('#grCount');
      const v = Math.max(1, Number(inp.value) - 1);
      inp.value = v;
      state.groceryRoommates = v;
      reload();
    });
    $('#grPlus').addEventListener('click', () => {
      const inp = $('#grCount');
      const v = Math.min(10, Number(inp.value) + 1);
      inp.value = v;
      state.groceryRoommates = v;
      reload();
    });
    $('#grCode').addEventListener('change', reload);
    reload();
  }

  /* ─── settings ────────────────────────────────────────── */
  function renderSettings(main) {
    const theme = localStorage.getItem(Api.KEYS.theme) || 'system';
    const lang = I18n.getLang();
    main.innerHTML = `
      <div class="stack">
        <div class="panel stack">
          <h2 class="section-title">${esc(I18n.t('settings'))}</h2>
          <div class="field"><label>${esc(I18n.t('language'))}</label>
            <select id="stLang">
              <option value="uz"${lang === 'uz' ? ' selected' : ''}>O‘zbek</option>
              <option value="ru"${lang === 'ru' ? ' selected' : ''}>Русский</option>
              <option value="en"${lang === 'en' ? ' selected' : ''}>English</option>
            </select></div>
          <div class="field"><label>${esc(I18n.t('theme'))}</label>
            <select id="stTheme">
              <option value="system"${theme === 'system' ? ' selected' : ''}>${esc(I18n.t('themeSystem'))}</option>
              <option value="light"${theme === 'light' ? ' selected' : ''}>${esc(I18n.t('themeLight'))}</option>
              <option value="dark"${theme === 'dark' ? ' selected' : ''}>${esc(I18n.t('themeDark'))}</option>
            </select></div>
          <a class="btn btn-ghost btn-block" href="/privacy/" target="_blank" rel="noopener">${esc(I18n.t('privacy'))}</a>
          <a class="btn btn-ghost btn-block" href="/terms/" target="_blank" rel="noopener">${esc(I18n.t('terms'))}</a>
          <button type="button" class="btn btn-ghost btn-block" id="stLogout">${esc(I18n.t('logout'))}</button>
          <button type="button" class="btn btn-danger btn-block" id="stDelete">${esc(I18n.t('deleteAccount'))}</button>
        </div>
      </div>`;

    $('#stLang').addEventListener('change', () => {
      I18n.setLang($('#stLang').value);
      updateChrome(state.route);
      renderSettings(main);
      toast(I18n.t('done'));
    });
    $('#stTheme').addEventListener('change', () => {
      applyTheme($('#stTheme').value);
      toast(I18n.t('done'));
    });
    $('#stLogout').addEventListener('click', async () => {
      try { await Api.logout(); } catch (_) { /* */ }
      Api.clearAuth();
      setCachedProfile(null);
      toast(I18n.t('logout'));
      navigate('login');
    });
    $('#stDelete').addEventListener('click', async () => {
      const password = prompt(I18n.t('password') + ':');
      if (password == null) return;
      if (!confirm(I18n.t('confirmDelete'))) return;
      const res = await Api.deleteAccount(password);
      if (!res.ok) { toast(res.error || 'Xato'); return; }
      Api.clearAuth();
      setCachedProfile(null);
      toast(I18n.t('done'));
      navigate('login');
    });
  }

  /* ─── boot ────────────────────────────────────────────── */
  function bindShell() {
    $('#btnSettings').addEventListener('click', () => navigate('settings'));
    $$('#bottomNav button').forEach((b) => {
      b.addEventListener('click', () => navigate(b.dataset.tab));
    });
    window.addEventListener('hashchange', route);
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if ((localStorage.getItem(Api.KEYS.theme) || 'system') === 'system') applyTheme('system');
    });
  }

  function init() {
    I18n.setLang(I18n.getLang());
    applyTheme();
    if (!localStorage.getItem(Api.KEYS.group)) setGroupCode('home_default');
    bindShell();
    if (!location.hash) {
      location.hash = Api.isLoggedIn() ? '#/housing' : '#/login';
    } else {
      route();
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
