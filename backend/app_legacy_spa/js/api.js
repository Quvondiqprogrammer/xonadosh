/** XonaDosh API client — same contracts as Flutter */
const Api = (() => {
  const BASE = '/api';
  const KEYS = {
    token: 'xd_web_token',
    refresh: 'xd_web_refresh',
    expires: 'xd_web_expires',
    user: 'xd_web_user',
    lang: 'xd_web_lang',
    theme: 'xd_web_theme',
    group: 'xd_web_group',
  };

  function getToken() {
    return localStorage.getItem(KEYS.token) || '';
  }

  function getUser() {
    try { return JSON.parse(localStorage.getItem(KEYS.user) || 'null'); }
    catch { return null; }
  }

  function saveAuth(data) {
    if (data.token) localStorage.setItem(KEYS.token, data.token);
    if (data.refresh_token) localStorage.setItem(KEYS.refresh, data.refresh_token);
    if (data.expires_at != null) localStorage.setItem(KEYS.expires, String(data.expires_at));
    if (data.user) localStorage.setItem(KEYS.user, JSON.stringify(data.user));
    else if (data.username) {
      localStorage.setItem(KEYS.user, JSON.stringify({
        username: data.username,
        full_name: data.user?.full_name || data.username,
        phone_number: data.user?.phone_number || '',
      }));
    }
  }

  function clearAuth() {
    [KEYS.token, KEYS.refresh, KEYS.expires, KEYS.user].forEach(k => localStorage.removeItem(k));
  }

  function isLoggedIn() {
    return !!getToken();
  }

  async function request(path, { method = 'GET', data, auth = true, query } = {}) {
    let url = BASE + '/' + path.replace(/^\//, '');
    if (query) {
      const qs = new URLSearchParams();
      Object.entries(query).forEach(([k, v]) => {
        if (v !== undefined && v !== null && v !== '') qs.set(k, String(v));
      });
      const s = qs.toString();
      if (s) url += (url.includes('?') ? '&' : '?') + s;
    }
    const headers = { Accept: 'application/json' };
    if (data !== undefined) headers['Content-Type'] = 'application/json';
    if (auth) {
      const t = getToken();
      if (t) headers.Authorization = 'Bearer ' + t;
    }
    let res;
    try {
      res = await fetch(url, {
        method,
        headers,
        body: data !== undefined ? JSON.stringify(data) : undefined,
      });
    } catch (e) {
      return { ok: false, error: 'Tarmoq xatosi. Internetni tekshiring.' };
    }
    let body = null;
    const text = await res.text();
    try { body = text ? JSON.parse(text) : {}; }
    catch { body = { ok: false, error: 'Noto‘g‘ri javob' }; }

    if (res.status === 401 && auth && localStorage.getItem(KEYS.refresh)) {
      const refreshed = await refresh();
      if (refreshed) return request(path, { method, data, auth, query });
      clearAuth();
    }
    if (body && typeof body === 'object') return body;
    return { ok: false, error: 'Server xatosi (' + res.status + ')' };
  }

  async function refresh() {
    const rt = localStorage.getItem(KEYS.refresh);
    if (!rt) return false;
    const r = await request('auth_refresh.php', {
      method: 'POST',
      data: { refresh_token: rt },
      auth: false,
    });
    if (r.ok && r.token) {
      saveAuth(r);
      return true;
    }
    return false;
  }

  return {
    KEYS,
    getToken,
    getUser,
    saveAuth,
    clearAuth,
    isLoggedIn,
    request,
    // Auth
    register: (d) => request('auth_register.php', { method: 'POST', data: d, auth: false }),
    login: (d) => request('auth_login.php', { method: 'POST', data: d, auth: false }),
    logout: () => request('auth_logout.php', { method: 'POST', data: {} }),
    me: () => request('auth_me.php'),
    deleteAccount: (password) => request('account_delete.php', {
      method: 'POST',
      data: { password, confirm: 'delete' },
    }),
    // Housing
    universities: (q = {}) => request('xonadosh_universities_get.php', { query: q, auth: false }),
    listings: (q = {}) => request('xonadosh_listings_get.php', { query: q, auth: false }),
    createListing: (d) => request('xonadosh_listing_create.php', { method: 'POST', data: d }),
    deleteListing: (id) => request('xonadosh_listing_delete.php', { method: 'POST', data: { listing_id: id } }),
    commute: (q) => request('xonadosh_commute_calc.php', { query: q, auth: false }),
    // Matching
    profiles: (q = {}) => request('xonadosh_profiles.php', { query: q }),
    saveProfile: (d) => request('xonadosh_profiles.php', { method: 'POST', data: d }),
    match: (q = {}) => request('xonadosh_match.php', { query: q }),
    // Coliving
    chores: (group_code = 'home_default') => request('xonadosh_chores.php', { query: { group_code }, auth: false }),
    choreAction: (d) => request('xonadosh_chores.php', { method: 'POST', data: d, auth: false }),
    recipes: (q = {}) => request('xonadosh_recipes.php', { query: q, auth: false }),
    recipeAction: (d) => request('xonadosh_recipes.php', { method: 'POST', data: d }),
    grocery: (q) => request('xonadosh_grocery_calc.php', { query: q, auth: false }),
    // Karma & Reputation
    karma: (group_code = 'home_default') => request('xonadosh_karma.php', { query: { group_code }, auth: false }),
    karmaAction: (d) => request('xonadosh_karma.php', { method: 'POST', data: d, auth: false }),
    // Anonymous Polls
    polls: (group_code = 'home_default') => request('xonadosh_polls.php', { query: { group_code }, auth: false }),
    pollAction: (d) => request('xonadosh_polls.php', { method: 'POST', data: d, auth: false }),
    // Finances & Debts
    finances: (group_code = 'home_default') => request('xonadosh_finances.php', { query: { group_code }, auth: false }),
    financeAction: (d) => request('xonadosh_finances.php', { method: 'POST', data: d, auth: false }),
    report: (d) => request('report.php', { method: 'POST', data: d }),
  };
})();
