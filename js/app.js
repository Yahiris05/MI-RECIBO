import { DEFAULT_DOCUMENTS, DEFAULT_REMINDERS, DEFAULT_STATS, DEFAULT_PROFILE } from './mockData.js';
import { renderIcon } from './icons.js';

// Application State
const state = {
  documents: [],
  reminders: [],
  stats: {},
  profile: {},
  currentScreen: 'splash',
  isLoggedIn: false,
  searchQuery: '',
  searchFilter: 'Todos',
  reminderTab: 'Próximos',
  activeScannedReceipt: null, // Details of receipt currently scanned
  editingDocId: null, // ID of document currently being edited
  editingReminderId: null // ID of reminder currently being edited
};

// Initialize App
function init() {
  loadFromStorage();
  setupEventListeners();
  
  // Check if already logged in from previous session
  if (state.isLoggedIn) {
    navigateTo('dashboard');
  } else {
    navigateTo('splash');
  }
}

// LocalStorage Synchronization
function loadFromStorage() {
  const docs = localStorage.getItem('mr_documents');
  const rems = localStorage.getItem('mr_reminders');
  const prof = localStorage.getItem('mr_profile');
  const logged = localStorage.getItem('mr_is_logged_in');

  state.documents = docs ? JSON.parse(docs) : [...DEFAULT_DOCUMENTS];
  state.reminders = rems ? JSON.parse(rems) : [...DEFAULT_REMINDERS];
  state.profile = prof ? JSON.parse(prof) : { ...DEFAULT_PROFILE };
  state.isLoggedIn = logged === 'true';

  // Recalculate stats based on actual lists with default baselines
  recalculateStats();

  // Always save default data on first load
  if (!docs) saveToStorage();
}

function saveToStorage() {
  localStorage.setItem('mr_documents', JSON.stringify(state.documents));
  localStorage.setItem('mr_reminders', JSON.stringify(state.reminders));
  localStorage.setItem('mr_stats', JSON.stringify(state.stats));
  localStorage.setItem('mr_profile', JSON.stringify(state.profile));
  localStorage.setItem('mr_is_logged_in', state.isLoggedIn);
}

// Recalculate statistics dynamically to match high-fidelity mockup baselines
function recalculateStats() {
  // Mockup has 128 documents initially with 6 default list items. Base offset = 122.
  state.stats.docsCount = 122 + state.documents.length;
  
  // Count pending reminders
  state.stats.pendingReminders = state.reminders.filter(r => r.status === 'pending').length;
  
  // Mockup has 18 invoices this month initially with 4 default facturas. Base offset = 14.
  const facturasCount = state.documents.filter(d => d.type === 'Factura').length;
  state.stats.monthlyInvoices = 14 + facturasCount;
  
  // Mockup has 7 categories initially.
  const uniqueCats = new Set(state.documents.map(d => d.category));
  state.stats.categoriesCount = Math.max(7, uniqueCats.size);
}

// Navigates and renders screens
function navigateTo(screenId) {
  state.currentScreen = screenId;
  
  // Hide all screens
  document.querySelectorAll('.app-screen').forEach(screen => {
    screen.classList.remove('active');
  });

  // Show target screen
  const targetScreen = document.getElementById(`screen-${screenId}`);
  if (targetScreen) {
    targetScreen.classList.add('active');
  }

  // Update Status Bar Style (dark status bar on dark background screens)
  const statusBar = document.getElementById('app-status-bar');
  if (statusBar) {
    if (screenId === 'splash' || screenId === 'scanner') {
      statusBar.classList.add('dark-status');
    } else {
      statusBar.classList.remove('dark-status');
    }
  }

  // Render the dynamic content of the screen
  renderScreenContent(screenId);

  // Manage Bottom Navigation visibility and active states
  const bottomNav = document.getElementById('bottom-nav');
  const navScreens = ['dashboard', 'documents', 'reminders', 'profile'];
  
  if (navScreens.includes(screenId)) {
    bottomNav.style.display = 'flex';
    // Highlight correct tab
    document.querySelectorAll('.nav-item').forEach(btn => {
      btn.classList.remove('active');
      const target = btn.dataset.screen;
      if (target === screenId) {
        btn.classList.add('active');
      }
    });
  } else {
    bottomNav.style.display = 'none';
  }
}

// Router render pipeline
function renderScreenContent(screenId) {
  switch (screenId) {
    case 'dashboard':
      renderDashboard();
      break;
    case 'documents':
      renderDocuments();
      break;
    case 'reminders':
      renderReminders();
      break;
    case 'profile':
      renderProfile();
      break;
    case 'add-document':
      renderAddDocumentForm();
      break;
  }
}

// 1. Render Dashboard
function renderDashboard() {
  const welcomeName = document.getElementById('dash-welcome-name');
  welcomeName.textContent = `¡Hola, ${state.profile.name.split(' ')[0]}!`;

  // Update numbers
  document.getElementById('stat-docs-count').textContent = state.stats.docsCount;
  document.getElementById('stat-reminders-count').textContent = state.stats.pendingReminders;
  document.getElementById('stat-invoices-count').textContent = state.stats.monthlyInvoices;
  document.getElementById('stat-categories-count').textContent = state.stats.categoriesCount;

  // Next reminder panel
  const upcomingReminderContainer = document.getElementById('upcoming-reminder-container');
  const upcoming = state.reminders.find(r => r.status === 'pending');
  
  if (upcoming) {
    upcomingReminderContainer.innerHTML = `
      <div class="reminder-bar-card" id="dash-next-reminder-card">
        <div class="reminder-bar-info">
          <div class="reminder-bar-icon-box">
            ${renderIcon('calendar', 20)}
          </div>
          <div class="reminder-bar-details">
            <h4>${upcoming.title}</h4>
            <p>Vence en ${upcoming.daysLeft} días &bull; ${formatDateSpanish(upcoming.date)}</p>
          </div>
        </div>
        <div class="profile-link-chevron">
          ${renderIcon('chevronRight', 18)}
        </div>
      </div>
    `;
    document.getElementById('dash-next-reminder-card').addEventListener('click', () => {
      navigateTo('reminders');
    });
  } else {
    upcomingReminderContainer.innerHTML = `
      <div style="text-align: center; padding: 20px; font-size: 0.75rem; color: var(--text-muted); background: white; border-radius: var(--radius-md);">
        No tienes recordatorios pendientes
      </div>
    `;
  }

  // Bell badge update
  const pendingCount = state.reminders.filter(r => r.status === 'pending').length;
  const bellBadge = document.getElementById('dash-bell-badge');
  if (bellBadge) {
    if (pendingCount > 0) {
      bellBadge.style.display = 'flex';
      bellBadge.textContent = pendingCount;
    } else {
      bellBadge.style.display = 'none';
    }
  }

  // Render recent 3 documents
  const recentDocsList = document.getElementById('recent-docs-list');
  const recentDocs = state.documents.slice(0, 3);

  recentDocsList.innerHTML = recentDocs.map(doc => `
    <div class="doc-list-item" data-doc-id="${doc.id}">
      <div class="doc-item-left">
        <div class="doc-item-icon">
          ${renderIcon('document', 20)}
        </div>
        <div class="doc-item-details">
          <h4>${doc.supplier}</h4>
          <p>${formatDateSpanish(doc.date)}</p>
        </div>
      </div>
      <div class="doc-item-badge">${doc.format || 'PDF'}</div>
    </div>
  `).join('');

  // Bind clicks to details modal
  recentDocsList.querySelectorAll('.doc-list-item').forEach(item => {
    item.addEventListener('click', () => {
      showDocumentDetails(item.dataset.docId);
    });
  });
}

// 2. Render Documents List
function renderDocuments() {
  const query = state.searchQuery.toLowerCase().trim();
  const filter = state.searchFilter;

  // Filter
  const filtered = state.documents.filter(doc => {
    const matchesSearch = doc.supplier.toLowerCase().includes(query) || 
                          doc.category.toLowerCase().includes(query) ||
                          doc.notes.toLowerCase().includes(query);
    
    if (filter === 'Todos') return matchesSearch;
    if (filter === 'Facturas' && doc.type === 'Factura') return matchesSearch;
    if (filter === 'Recibos' && doc.type === 'Recibo') return matchesSearch;
    if (filter === 'Comprobantes' && doc.type === 'Comprobante') return matchesSearch;
    return false;
  });

  const docsContainer = document.getElementById('docs-list-container');
  
  if (filtered.length === 0) {
    docsContainer.innerHTML = `
      <div style="text-align: center; padding: 40px 20px; color: var(--text-muted); font-size: 0.85rem;">
        <div style="margin-bottom: 10px;">${renderIcon('search', 32, 'style="opacity: 0.3;"')}</div>
        No se encontraron comprobantes
      </div>
    `;
    return;
  }

  docsContainer.innerHTML = filtered.map(doc => `
    <div class="doc-list-item" data-doc-id="${doc.id}">
      <div class="doc-item-left">
        <div class="doc-item-icon">
          ${renderIcon('document', 20)}
        </div>
        <div class="doc-item-details">
          <h4>${doc.supplier}</h4>
          <p>${formatDateSpanish(doc.date)}</p>
        </div>
      </div>
      <div class="doc-item-badge">${doc.format || 'PDF'}</div>
    </div>
  `).join('');

  // Bind clicks
  docsContainer.querySelectorAll('.doc-list-item').forEach(item => {
    item.addEventListener('click', () => {
      showDocumentDetails(item.dataset.docId);
    });
  });
}

// 3. Render Reminders
function renderReminders() {
  const container = document.getElementById('reminders-list-container');
  const activeTab = state.reminderTab;

  const filtered = state.reminders.filter(rem => {
    if (activeTab === 'Próximos') return rem.status === 'pending';
    if (activeTab === 'Completados') return rem.status === 'completed';
    // Calendario
    return true;
  });

  if (filtered.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; padding: 40px 20px; color: var(--text-muted); font-size: 0.85rem;">
        No hay recordatorios en esta sección
      </div>
    `;
    return;
  }

  container.innerHTML = filtered.map(rem => `
    <div class="reminder-item-card" data-rem-id="${rem.id}">
      <div class="reminder-item-top">
        <div class="reminder-item-icon-box">
          ${renderIcon('calendar', 20)}
        </div>
        <div class="reminder-item-text">
          <h4>${rem.title}</h4>
          <p>${rem.status === 'pending' ? `Vence en ${rem.daysLeft} días` : 'Completado'}</p>
        </div>
      </div>
      <div class="reminder-item-bottom">
        <div class="reminder-item-date">${formatDateSpanish(rem.date)}</div>
        <div class="reminder-item-tag ${rem.urgency.toLowerCase()}">${rem.urgency}</div>
      </div>
    </div>
  `).join('');

  // Click card to view details (which has toggle, edit, and delete options)
  container.querySelectorAll('.reminder-item-card').forEach(card => {
    card.addEventListener('click', () => {
      showReminderDetails(card.dataset.remId);
    });
  });
}

// 4. Render Profile
function renderProfile() {
  document.getElementById('profile-comp-name').textContent = state.profile.name;
  document.getElementById('profile-comp-rnc').textContent = `RNC: ${state.profile.rnc}`;
  document.getElementById('profile-comp-email').textContent = state.profile.email;
  document.getElementById('profile-comp-phone').textContent = state.profile.phone;
}

// 5. Add Document Pre-filling (Supports Create and Edit)
function renderAddDocumentForm() {
  const form = document.getElementById('add-document-form');
  form.reset();

  const headerTitle = document.querySelector('#screen-add-document .app-header-title');
  const submitBtn = document.querySelector('#screen-add-document .form-submit-btn');

  if (state.editingDocId) {
    if (headerTitle) headerTitle.textContent = "Editar documento";
    if (submitBtn) submitBtn.textContent = "Actualizar documento";
    
    const doc = state.documents.find(d => d.id === state.editingDocId);
    if (doc) {
      document.getElementById('form-proveedor').value = doc.supplier;
      document.getElementById('form-tipo').value = doc.type;
      document.getElementById('form-fecha').value = doc.date;
      document.getElementById('form-categoria').value = doc.category;
      document.getElementById('form-monto').value = doc.amount;
      document.getElementById('form-notas').value = doc.notes || '';
    }
  } else {
    if (headerTitle) headerTitle.textContent = "Agregar documento";
    if (submitBtn) submitBtn.textContent = "Guardar documento";

    if (state.activeScannedReceipt) {
      const data = state.activeScannedReceipt;
      document.getElementById('form-proveedor').value = data.supplier;
      document.getElementById('form-tipo').value = data.type;
      document.getElementById('form-fecha').value = data.date;
      document.getElementById('form-categoria').value = data.category;
      document.getElementById('form-monto').value = data.amount;
      document.getElementById('form-notas').value = data.notes;
      
      state.activeScannedReceipt = null;
    } else {
      document.getElementById('form-fecha').value = new Date().toISOString().split('T')[0];
    }
  }
}

// 6. Modal Details display
function showDocumentDetails(docId) {
  const doc = state.documents.find(d => d.id === docId);
  if (!doc) return;

  const overlay = document.getElementById('app-modal');
  const container = document.getElementById('modal-content-container');

  const formattedMonto = parseFloat(doc.amount || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  
  container.innerHTML = `
    <div class="modal-header-row">
      <div class="modal-title">${doc.supplier}</div>
      <button class="modal-close-btn" id="modal-close-trigger">
        ${renderIcon('close', 20)}
      </button>
    </div>
    <div class="modal-body">
      <div class="modal-detail-row">
        <span class="modal-detail-label">Tipo de documento</span>
        <span class="modal-detail-value">${doc.type}</span>
      </div>
      <div class="modal-detail-row">
        <span class="modal-detail-label">Fecha</span>
        <span class="modal-detail-value">${formatDateSpanish(doc.date)}</span>
      </div>
      <div class="modal-detail-row">
        <span class="modal-detail-label">Categoría</span>
        <span class="modal-detail-value">${doc.category}</span>
      </div>
      <div class="modal-detail-row">
        <span class="modal-detail-label">Monto</span>
        <span class="modal-detail-value amount">RD$ ${formattedMonto}</span>
      </div>
      <div class="modal-detail-row">
        <span class="modal-detail-label">Notas</span>
        <span class="modal-detail-value">${doc.notes || 'Ninguna'}</span>
      </div>
      
      <div class="modal-receipt-preview">
        <div class="receipt-title">${doc.supplier.toUpperCase()}</div>
        <div style="text-align: center; font-size: 0.55rem; color: #555; margin-bottom: 5px;">RNC: 1-01-12345-6</div>
        <div class="receipt-divider"></div>
        <div class="receipt-row">
          <span>DESCRIPCION</span>
          <span>VALOR</span>
        </div>
        <div class="receipt-divider"></div>
        <div class="receipt-row">
          <span>COMPROBANTE SERVICIO</span>
          <span>RD$ ${formattedMonto}</span>
        </div>
        <div class="receipt-divider"></div>
        <div class="receipt-row" style="font-weight: bold;">
          <span>TOTAL</span>
          <span>RD$ ${formattedMonto}</span>
        </div>
        <div style="text-align: center; margin-top: 8px; font-size: 0.55rem; color: #777;">¡Gracias por su registro!</div>
      </div>
      
      <div style="display: flex; gap: 10px; margin-top: 15px;">
        <button id="modal-edit-btn" style="flex: 1; background: rgba(26, 54, 93, 0.08); color: #1a365d; border: none; padding: 12px; border-radius: var(--radius-md); font-weight: 600; cursor: pointer; font-size: 0.78rem; transition: var(--transition-fast); display: flex; align-items: center; justify-content: center; gap: 6px;">
          ${renderIcon('edit', 14)} Editar
        </button>
        <button id="modal-delete-btn" style="flex: 1; background: rgba(220, 53, 69, 0.08); color: #dc3545; border: none; padding: 12px; border-radius: var(--radius-md); font-weight: 600; cursor: pointer; font-size: 0.78rem; transition: var(--transition-fast); display: flex; align-items: center; justify-content: center; gap: 6px;">
          ${renderIcon('trash', 14)} Eliminar
        </button>
      </div>
    </div>
  `;

  overlay.classList.add('active');

  // Close bindings
  document.getElementById('modal-close-trigger').addEventListener('click', hideModal);
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) hideModal();
  });

  // Edit document
  document.getElementById('modal-edit-btn').addEventListener('click', () => {
    state.editingDocId = docId;
    hideModal();
    navigateTo('add-document');
  });

  // Delete document
  document.getElementById('modal-delete-btn').addEventListener('click', () => {
    state.documents = state.documents.filter(d => d.id !== docId);
    recalculateStats();
    saveToStorage();
    hideModal();
    renderScreenContent(state.currentScreen);
  });
}

function hideModal() {
  document.getElementById('app-modal').classList.remove('active');
}

// 7. Reminder CRUD Details and Forms
function showReminderDetails(remId) {
  const rem = state.reminders.find(r => r.id === remId);
  if (!rem) return;

  const overlay = document.getElementById('app-modal');
  const container = document.getElementById('modal-content-container');

  container.innerHTML = `
    <div class="modal-header-row">
      <div class="modal-title">Detalles de la alerta</div>
      <button class="modal-close-btn" id="modal-close-trigger">
        ${renderIcon('close', 20)}
      </button>
    </div>
    <div class="modal-body">
      <div class="modal-detail-row">
        <span class="modal-detail-label">Título</span>
        <span class="modal-detail-value" style="font-weight: bold; color: var(--primary-navy);">${rem.title}</span>
      </div>
      <div class="modal-detail-row">
        <span class="modal-detail-label">Fecha de vencimiento</span>
        <span class="modal-detail-value">${formatDateSpanish(rem.date)}</span>
      </div>
      <div class="modal-detail-row">
        <span class="modal-detail-label">Días restantes</span>
        <span class="modal-detail-value">${rem.daysLeft} días</span>
      </div>
      <div class="modal-detail-row">
        <span class="modal-detail-label">Urgencia</span>
        <span class="modal-detail-value">
          <span class="reminder-item-tag ${rem.urgency.toLowerCase()}">${rem.urgency}</span>
        </span>
      </div>
      <div class="modal-detail-row">
        <span class="modal-detail-label">Estado</span>
        <span class="modal-detail-value" style="font-weight: 600; color: ${rem.status === 'completed' ? 'var(--status-success-text)' : 'var(--accent-orange)'}">
          ${rem.status === 'completed' ? 'Completado' : 'Pendiente'}
        </span>
      </div>

      <div style="display: flex; flex-direction: column; gap: 8px; margin-top: 15px;">
        <button id="modal-toggle-status-btn" style="background: rgba(12, 15, 29, 0.04); color: var(--text-dark); border: 1px solid rgba(0,0,0,0.06); padding: 12px; border-radius: var(--radius-md); font-weight: 600; cursor: pointer; font-size: 0.78rem; transition: var(--transition-fast); display: flex; align-items: center; justify-content: center; gap: 6px;">
          ${renderIcon('check', 14)} Marcar como ${rem.status === 'pending' ? 'Completado' : 'Pendiente'}
        </button>
        
        <div style="display: flex; gap: 10px;">
          <button id="modal-edit-rem-btn" style="flex: 1; background: rgba(26, 54, 93, 0.08); color: #1a365d; border: none; padding: 12px; border-radius: var(--radius-md); font-weight: 600; cursor: pointer; font-size: 0.78rem; transition: var(--transition-fast); display: flex; align-items: center; justify-content: center; gap: 6px;">
            ${renderIcon('edit', 14)} Editar
          </button>
          <button id="modal-delete-rem-btn" style="flex: 1; background: rgba(220, 53, 69, 0.08); color: #dc3545; border: none; padding: 12px; border-radius: var(--radius-md); font-weight: 600; cursor: pointer; font-size: 0.78rem; transition: var(--transition-fast); display: flex; align-items: center; justify-content: center; gap: 6px;">
            ${renderIcon('trash', 14)} Eliminar
          </button>
        </div>
      </div>
    </div>
  `;

  overlay.classList.add('active');

  // Close bindings
  document.getElementById('modal-close-trigger').addEventListener('click', hideModal);
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) hideModal();
  });

  // Toggle status
  document.getElementById('modal-toggle-status-btn').addEventListener('click', () => {
    rem.status = rem.status === 'pending' ? 'completed' : 'pending';
    recalculateStats();
    saveToStorage();
    hideModal();
    renderReminders();
  });

  // Edit reminder
  document.getElementById('modal-edit-rem-btn').addEventListener('click', () => {
    showReminderForm(rem.id);
  });

  // Delete reminder
  document.getElementById('modal-delete-rem-btn').addEventListener('click', () => {
    state.reminders = state.reminders.filter(r => r.id !== remId);
    recalculateStats();
    saveToStorage();
    hideModal();
    renderReminders();
  });
}

function showReminderForm(reminderId = null) {
  const overlay = document.getElementById('app-modal');
  const container = document.getElementById('modal-content-container');
  
  let titleVal = '';
  let dateVal = new Date().toISOString().split('T')[0];
  let urgencyVal = 'Normal';
  let modalTitle = 'Nuevo recordatorio';
  let buttonText = 'Guardar recordatorio';

  if (reminderId) {
    const rem = state.reminders.find(r => r.id === reminderId);
    if (rem) {
      titleVal = rem.title;
      dateVal = rem.date;
      urgencyVal = rem.urgency;
      modalTitle = 'Editar recordatorio';
      buttonText = 'Actualizar recordatorio';
    }
  }

  container.innerHTML = `
    <div class="modal-header-row">
      <div class="modal-title">${modalTitle}</div>
      <button class="modal-close-btn" id="modal-close-trigger">
        ${renderIcon('close', 20)}
      </button>
    </div>
    <div class="modal-body" style="padding-top: 15px;">
      <form id="reminder-modal-form">
        <div class="form-group" style="margin-bottom: 12px;">
          <label class="form-label" style="font-size: 0.72rem;">Título del recordatorio</label>
          <input type="text" id="rem-title" class="input-field" style="padding-left: 14px;" placeholder="Ej. Declaración ITBIS" required value="${titleVal}">
        </div>
        <div class="form-group" style="margin-bottom: 12px;">
          <label class="form-label" style="font-size: 0.72rem;">Fecha de vencimiento</label>
          <input type="date" id="rem-date" class="input-field" style="padding-left: 14px;" required value="${dateVal}">
        </div>
        <div class="form-group" style="margin-bottom: 20px;">
          <label class="form-label" style="font-size: 0.72rem;">Nivel de urgencia</label>
          <select id="rem-urgency" class="input-select">
            <option value="Normal" ${urgencyVal === 'Normal' ? 'selected' : ''}>Normal</option>
            <option value="Importante" ${urgencyVal === 'Importante' ? 'selected' : ''}>Importante</option>
          </select>
        </div>
        <button type="submit" class="form-submit-btn" style="margin-top: 0; width: 100%; height: 44px; font-size: 0.85rem;">
          ${buttonText}
        </button>
      </form>
    </div>
  `;

  overlay.classList.add('active');

  // Bind close triggers
  document.getElementById('modal-close-trigger').addEventListener('click', hideModal);
  
  // Handle form submit
  const remForm = document.getElementById('reminder-modal-form');
  remForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const title = document.getElementById('rem-title').value;
    const date = document.getElementById('rem-date').value;
    const urgency = document.getElementById('rem-urgency').value;

    // Calculate days left
    const today = new Date();
    today.setHours(0,0,0,0);
    const targetDate = new Date(date);
    targetDate.setHours(0,0,0,0);
    const diffTime = targetDate.getTime() - today.getTime();
    const daysLeft = Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));

    if (reminderId) {
      const index = state.reminders.findIndex(r => r.id === reminderId);
      if (index !== -1) {
        state.reminders[index] = {
          ...state.reminders[index],
          title,
          date,
          daysLeft,
          urgency
        };
      }
    } else {
      const newRem = {
        id: `rem-${Date.now()}`,
        title,
        date,
        daysLeft,
        urgency,
        status: 'pending'
      };
      state.reminders.unshift(newRem);
    }

    recalculateStats();
    saveToStorage();
    hideModal();
    renderReminders();
  });
}

// Date helper
function formatDateSpanish(dateStr) {
  if (!dateStr) return '';
  const parts = dateStr.split('-');
  if (parts.length !== 3) return dateStr;
  
  const months = [
    'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
    'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'
  ];
  
  const day = parseInt(parts[2], 10);
  const month = months[parseInt(parts[1], 10) - 1];
  const year = parts[0];
  
  return `${day < 10 ? '0' + day : day} ${month}, ${year}`;
}

// Event Bindings
function setupEventListeners() {
  // Navigation tabs
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', () => {
      const screen = btn.dataset.screen;
      if (screen) navigateTo(screen);
    });
  });

  // Scanner trigger floating button
  const fabScan = document.getElementById('nav-fab-btn');
  if (fabScan) {
    fabScan.addEventListener('click', (e) => {
      e.stopPropagation();
      navigateTo('scanner');
    });
  }

  // App Back Buttons
  document.querySelectorAll('.app-header-back').forEach(btn => {
    btn.addEventListener('click', () => {
      state.editingDocId = null; // Clear edit document state
      const customBack = btn.dataset.backScreen;
      if (customBack) {
        navigateTo(customBack);
      } else {
        navigateTo('dashboard');
      }
    });
  });

  // Splash/Onboarding Start
  const splashBtn = document.getElementById('splash-btn');
  if (splashBtn) {
    splashBtn.addEventListener('click', () => {
      navigateTo('login');
    });
  }

  // Password hide/show toggle
  const pwdToggle = document.getElementById('pwd-toggle');
  if (pwdToggle) {
    pwdToggle.addEventListener('click', () => {
      const pwdInput = document.getElementById('login-password');
      const isPwd = pwdInput.type === 'password';
      pwdInput.type = isPwd ? 'text' : 'password';
      pwdToggle.innerHTML = renderIcon(isPwd ? 'eyeOff' : 'eye', 18);
    });
  }

  // Login Form Submission
  const loginForm = document.getElementById('login-form');
  if (loginForm) {
    loginForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const email = document.getElementById('login-email').value;
      if (email) {
        state.isLoggedIn = true;
        saveToStorage();
        navigateTo('dashboard');
      }
    });
  }

  // Go to Register simulation
  const regTrigger = document.getElementById('register-trigger');
  if (regTrigger) {
    regTrigger.addEventListener('click', () => {
      alert('La simulación del sistema de registro utiliza el formulario de inicio de sesión empresarial. Puede ingresar con cualquier correo ficticio.');
    });
  }

  // Search input typing
  const searchInput = document.getElementById('doc-search-input');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      state.searchQuery = e.target.value;
      renderDocuments();
    });
  }

  // Search filter tag selector
  document.querySelectorAll('.filter-tag').forEach(tag => {
    tag.addEventListener('click', () => {
      document.querySelectorAll('.filter-tag').forEach(t => t.classList.remove('active'));
      tag.classList.add('active');
      state.searchFilter = tag.dataset.filter;
      renderDocuments();
    });
  });

  // Reminders Filter tabs clicks
  document.querySelectorAll('.reminder-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.reminder-tab-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      state.reminderTab = btn.dataset.tab;
      renderReminders();
    });
  });

  // Scanner actions: Capture trigger with laser animation
  const captureBtn = document.getElementById('scanner-capture-trigger');
  if (captureBtn) {
    captureBtn.addEventListener('click', () => {
      const laserLine = document.getElementById('laser-scanner');
      laserLine.classList.add('scanning');
      captureBtn.style.pointerEvents = 'none';

      // Brief flash effect
      const viewport = document.querySelector('.camera-viewport');
      const flash = document.createElement('div');
      flash.style.position = 'absolute';
      flash.style.top = '0';
      flash.style.left = '0';
      flash.style.width = '100%';
      flash.style.height = '100%';
      flash.style.background = '#fff';
      flash.style.zIndex = '100';
      flash.style.opacity = '1';
      flash.style.transition = 'opacity 0.5s ease-out';
      viewport.appendChild(flash);
      
      setTimeout(() => {
        flash.style.opacity = '0';
      }, 50);
      
      setTimeout(() => {
        flash.remove();
      }, 550);

      // OCR scan simulation: 2 seconds
      setTimeout(() => {
        laserLine.classList.remove('scanning');
        captureBtn.style.pointerEvents = 'auto';

        state.activeScannedReceipt = {
          supplier: "Office Depot",
          type: "Factura",
          date: "2024-05-07",
          category: "Útiles de oficina",
          amount: 4920.00,
          notes: "Escaneo inteligente de factura de suministros."
        };

        navigateTo('add-document');
      }, 2000);
    });
  }

  // Camera close trigger
  const closeScanner = document.getElementById('scanner-close-trigger');
  if (closeScanner) {
    closeScanner.addEventListener('click', () => navigateTo('dashboard'));
  }

  // Add Document form submission
  const docForm = document.getElementById('add-document-form');
  if (docForm) {
    docForm.addEventListener('submit', (e) => {
      e.preventDefault();
      
      const supplier = document.getElementById('form-proveedor').value;
      const type = document.getElementById('form-tipo').value;
      const date = document.getElementById('form-fecha').value;
      const category = document.getElementById('form-categoria').value;
      const amount = parseFloat(document.getElementById('form-monto').value) || 0;
      const notes = document.getElementById('form-notas').value;

      if (!supplier) {
        alert('Por favor ingrese el proveedor');
        return;
      }

      if (state.editingDocId) {
        const index = state.documents.findIndex(d => d.id === state.editingDocId);
        if (index !== -1) {
          state.documents[index] = {
            ...state.documents[index],
            supplier,
            type,
            date,
            category,
            amount,
            notes
          };
        }
        state.editingDocId = null;
      } else {
        const newDoc = {
          id: `doc-${Date.now()}`,
          supplier,
          type,
          date,
          category,
          amount,
          notes,
          format: 'PDF'
        };
        state.documents.unshift(newDoc);
      }
      
      recalculateStats();
      saveToStorage();
      navigateTo('documents');
    });
  }

  // Reset Demo button listener
  const resetBtn = document.getElementById('profile-reset-btn');
  if (resetBtn) {
    resetBtn.addEventListener('click', () => {
      if (confirm('¿Desea restablecer todos los datos al estado de fábrica de la demostración?')) {
        localStorage.clear();
        loadFromStorage();
        alert('Datos restablecidos con éxito.');
        navigateTo('dashboard');
      }
    });
  }

  // Logout trigger button
  const logoutBtn = document.getElementById('profile-logout-btn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', () => {
      state.isLoggedIn = false;
      saveToStorage();
      navigateTo('login');
    });
  }

  // Add Reminder button
  const addReminderBtn = document.getElementById('add-reminder-btn');
  if (addReminderBtn) {
    addReminderBtn.addEventListener('click', () => {
      showReminderForm();
    });
  }
}

// Start execution
document.addEventListener('DOMContentLoaded', init);
export { renderIcon };
