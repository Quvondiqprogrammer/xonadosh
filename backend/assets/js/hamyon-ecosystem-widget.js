/**
 * Hamyon AI Universal Ecosystem Navigation Widget
 * (C) 2026 Hamyon AI Ekotizimi. Barcha huquqlar himoyalangan.
 *
 * Ushbu skript barcha mustaqil web loihalarga (taklf.uz, kinochiaka.uz, shoply.uz,
 * xonadoshim.uz, zargo.uz, inbaraka.uz, helpme.uz) o'rnatiladi va ularni bitta
 * yagona tana kabi bog'laydi.
 */
(function () {
  'use strict';

  if (window.__HAMYON_ECOSYSTEM_NAV_LOADED__) return;
  window.__HAMYON_ECOSYSTEM_NAV_LOADED__ = true;

  const ECOSYSTEM_APPS = [
    {
      id: 'hamyonai',
      name: 'Hamyon AI',
      subtitle: 'Markaziy Moliya & Hamyon',
      icon: '💰',
      color: '#4F46E5',
      url: 'https://hamyon-ai.uz',
      scheme: 'hamyonai://'
    },
    {
      id: 'zargo',
      name: 'ZarGO Taxi',
      subtitle: '0% Komissiya • Tezkor Qatnov',
      icon: '🚖',
      color: '#F59E0B',
      url: 'https://zargo.uz',
      scheme: 'zargo://'
    },
    {
      id: 'mydokon',
      name: 'MyDokon (Shoply)',
      subtitle: 'Bulutli Kassa & POS Ombor',
      icon: '🏪',
      color: '#3B82F6',
      url: 'https://shoply.uz',
      scheme: 'mydokon://'
    },
    {
      id: 'taklf',
      name: 'taklf.uz',
      subtitle: 'Smart Taklifnomalar & RSVP',
      icon: '💌',
      color: '#8B5CF6',
      url: 'https://taklf.uz',
      scheme: 'taklf://'
    },
    {
      id: 'xonadosh',
      name: 'XonaDosh',
      subtitle: 'Talabalar Ijarasi & Sherik',
      icon: '🏠',
      color: '#10B981',
      url: 'https://xonadoshim.uz',
      scheme: 'xonadosh://'
    },
    {
      id: 'inbaraka',
      name: 'inBaraka',
      subtitle: 'P2P Bozor & Avto Elonlar',
      icon: '🛍️',
      color: '#0D9488',
      url: 'https://barakam.uz',
      scheme: 'inbaraka://'
    },
    {
      id: 'ikkinchi',
      name: 'ikkinchi',
      subtitle: 'Ikkinchi Qo‘l & Sovchilik',
      icon: '💍',
      color: '#E11D48',
      url: 'https://ikkinchi.uz',
      scheme: 'ikkinchi://'
    },
    {
      id: 'helpme',
      name: 'Helpme',
      subtitle: 'Tezkor Ustalar & SOS Yordam',
      icon: '🛠️',
      color: '#06B6D4',
      url: 'https://helpme.uz',
      scheme: 'helpme://'
    },
    {
      id: 'kinochiaka',
      name: 'Kinochiaka.uz',
      subtitle: 'Onlayn Kinoteatr & Seriallar',
      icon: '🎬',
      color: '#E50914',
      url: 'https://kinochiaka.uz',
      scheme: 'kinochiaka://'
    }
  ];

  const CSS = `
    #hamyon-eco-pill {
      position: fixed;
      top: 14px;
      right: 16px;
      z-index: 999999;
      display: flex;
      align-items: center;
      gap: 8px;
      background: rgba(15, 23, 42, 0.92);
      color: #fff;
      padding: 7px 14px;
      border-radius: 999px;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 13px;
      font-weight: 700;
      box-shadow: 0 4px 20px rgba(0,0,0,0.25), 0 0 0 1px rgba(255,255,255,0.12);
      cursor: pointer;
      user-select: none;
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }
    #hamyon-eco-pill:hover {
      transform: translateY(-1px) scale(1.02);
      box-shadow: 0 6px 24px rgba(0,0,0,0.35), 0 0 0 1.5px rgba(99, 102, 241, 0.6);
      background: rgba(30, 41, 59, 0.96);
    }
    #hamyon-eco-pill .hamyon-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #10B981;
      box-shadow: 0 0 8px #10B981;
      display: inline-block;
    }
    #hamyon-eco-modal-overlay {
      position: fixed;
      inset: 0;
      background: rgba(15, 23, 42, 0.7);
      z-index: 1000000;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 16px;
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
      opacity: 0;
      transition: opacity 0.25s ease;
    }
    #hamyon-eco-modal-overlay.active {
      display: flex;
      opacity: 1;
    }
    #hamyon-eco-modal {
      background: #0F172A;
      color: #F8FAFC;
      border-radius: 24px;
      max-width: 620px;
      width: 100%;
      padding: 24px;
      box-shadow: 0 25px 60px -15px rgba(0, 0, 0, 0.7), 0 0 0 1px rgba(255,255,255,0.1);
      font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      transform: scale(0.96);
      transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
    }
    #hamyon-eco-modal-overlay.active #hamyon-eco-modal {
      transform: scale(1);
    }
    .hamyon-modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
      border-bottom: 1px solid rgba(255,255,255,0.08);
      padding-bottom: 16px;
    }
    .hamyon-modal-title {
      font-size: 20px;
      font-weight: 800;
      display: flex;
      align-items: center;
      gap: 10px;
      color: #fff;
    }
    .hamyon-modal-close {
      background: rgba(255,255,255,0.08);
      border: none;
      color: #94A3B8;
      width: 32px;
      height: 32px;
      border-radius: 50%;
      font-size: 18px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.15s ease;
    }
    .hamyon-modal-close:hover {
      background: rgba(255,255,255,0.18);
      color: #fff;
    }
    .hamyon-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;
    }
    @media (max-width: 600px) {
      .hamyon-grid {
        grid-template-columns: repeat(2, 1fr);
      }
    }
    .hamyon-app-card {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      padding: 14px;
      border-radius: 16px;
      background: rgba(255,255,255,0.04);
      border: 1px solid rgba(255,255,255,0.06);
      text-decoration: none;
      color: inherit;
      transition: all 0.2s ease;
      cursor: pointer;
    }
    .hamyon-app-card:hover {
      background: rgba(255,255,255,0.09);
      border-color: rgba(99, 102, 241, 0.4);
      transform: translateY(-2px);
    }
    .hamyon-app-icon {
      font-size: 26px;
      margin-bottom: 8px;
    }
    .hamyon-app-name {
      font-size: 14px;
      font-weight: 700;
      color: #fff;
      margin-bottom: 2px;
    }
    .hamyon-app-sub {
      font-size: 11px;
      color: #94A3B8;
      line-height: 1.3;
    }
    .hamyon-modal-footer {
      margin-top: 20px;
      padding-top: 14px;
      border-top: 1px solid rgba(255,255,255,0.08);
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 12px;
      color: #64748B;
    }
    .hamyon-badge-active {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 99px;
      font-size: 10px;
      font-weight: 800;
      background: #10B981;
      color: #fff;
      margin-left: 6px;
    }
  `;

  function init() {
    const styleEl = document.createElement('style');
    styleEl.textContent = CSS;
    document.head.appendChild(styleEl);

    // Pill
    const pill = document.createElement('div');
    pill.id = 'hamyon-eco-pill';
    pill.innerHTML = `
      <span class="hamyon-dot"></span>
      <span>Hamyon Ekotizimi</span>
      <span style="font-size: 10px; opacity: 0.6;">▼</span>
    `;
    document.body.appendChild(pill);

    // Overlay & Modal
    const overlay = document.createElement('div');
    overlay.id = 'hamyon-eco-modal-overlay';

    const currentHost = window.location.hostname;

    const cardsHtml = ECOSYSTEM_APPS.map(app => {
      const isCurrent = currentHost.includes(app.id) || app.url.includes(currentHost);
      return `
        <a class="hamyon-app-card" href="${app.url}" target="_blank" rel="noopener">
          <div class="hamyon-app-icon">${app.icon}</div>
          <div class="hamyon-app-name">
            ${app.name}
            ${isCurrent ? '<span class="hamyon-badge-active">HOZIR</span>' : ''}
          </div>
          <div class="hamyon-app-sub">${app.subtitle}</div>
        </a>
      `;
    }).join('');

    overlay.innerHTML = `
      <div id="hamyon-eco-modal">
        <div class="hamyon-modal-header">
          <div class="hamyon-modal-title">
            <span>🌐</span>
            <span>Hamyon AI Yagona Ekotizimi</span>
          </div>
          <button class="hamyon-modal-close" id="hamyon-eco-close-btn">&times;</button>
        </div>
        <div class="hamyon-grid">
          ${cardsHtml}
        </div>
        <div class="hamyon-modal-footer">
          <span>Yagona hisob (SSO) &amp; Markaziy Hamyon orqali bog‘langan</span>
          <span style="color: #10B981; font-weight: 700;">● Barcha servislari onlayn</span>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);

    function openModal() {
      overlay.classList.add('active');
    }
    function closeModal() {
      overlay.classList.remove('active');
    }

    pill.addEventListener('click', openModal);
    document.getElementById('hamyon-eco-close-btn').addEventListener('click', closeModal);
    overlay.addEventListener('click', function (e) {
      if (e.target === overlay) closeModal();
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && overlay.classList.contains('active')) {
        closeModal();
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
