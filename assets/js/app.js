// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// LiveView Hooks
let Hooks = {};
Hooks.LeafletMap = {
  mounted() {
    if (!window.L) { console.error("Leaflet not loaded"); return; }
    const pts = this._parsePoints();
    const initial = pts.length ? [pts[0].lat, pts[0].lng] : [33.72, -117.9];
    this.map = L.map(this.el).setView(initial, 10);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(this.map);
    this._renderMarkers(pts);
  },
  updated() {
    if (!this.map || !window.L) return;
    const pts = this._parsePoints();
    this._renderMarkers(pts);
  },
  destroyed() {
    if (this.map) this.map.remove();
  },
  _parsePoints() {
    try { return JSON.parse(this.el.dataset.points || "[]"); } catch (_e) { return []; }
  },
  _renderMarkers(points) {
    this.map.eachLayer(layer => { if (!(layer instanceof L.TileLayer)) this.map.removeLayer(layer); });
    points.forEach(p => L.circleMarker([p.lat, p.lng], { radius: 6 }).bindPopup(p.label || "").addTo(this.map));
  }
};

Hooks.FullCalendarPanel = {
  mounted() {
    // Resolve FullCalendar global from combined build
    const CalendarCtor = window.FullCalendar?.Calendar || window.Calendar || null;
    if (!CalendarCtor) {
      console.error("FullCalendar Calendar missing");
      return;
    }

    this._eventEls = new Map();

    const all = this._normalize(this._parseEvents());
    const focusId = this.el.dataset.focusId || null;
    const visible = this._visibleEvents(all, focusId);

    this.calendar = new CalendarCtor(this.el, {
      height: 'auto',
      initialView: 'timeGridWeek',
      events: visible,
      eventClick: (info) => this.pushEvent("calendar_event_click", { id: info.event.id }),
      eventDidMount: (arg) => {
        const id = arg.event.id;
        if (!id) return;
        this._eventEls.set(id, arg.el);
        if (id === focusId) requestAnimationFrame(() => this._highlight(id));
      },
      eventWillUnmount: (arg) => {
        const id = arg.event.id;
        if (id) this._eventEls.delete(id);
      }
    });

    this.calendar.render();
    if (focusId) this._gotoFocus(all, focusId);
  },
  updated() {
    if (!this.calendar) return;
    const all = this._normalize(this._parseEvents());
    const focusId = this.el.dataset.focusId || null;
    const visible = this._visibleEvents(all, focusId);

    this.calendar.removeAllEvents();
    this.calendar.addEventSource(visible);
    requestAnimationFrame(() => { if (focusId) this._highlight(focusId); });
    if (focusId) this._gotoFocus(all, focusId);
  },
  destroyed() {
    if (this.calendar) this.calendar.destroy();
    this._eventEls = null;
  },
  _parseEvents() {
    try { return JSON.parse(this.el.dataset.events || "[]"); } catch (_e) { return []; }
  },
  _normalize(events) {
    return (events || []).map(e => {
      const start = e.start || (e.date && e.time ? `${e.date}T${e.time}:00` : null);
      return Object.assign({}, e, { start });
    }).filter(e => !!e.start);
  },
  _visibleEvents(all, focusId) {
    if (!focusId) return [];
    const focus = all.find(ev => String(ev.id) === String(focusId));
    if (!focus) return [];
    const key = String(focus.assignees);
    return all.filter(ev => String(ev.assignees) === key);
  },
  _highlight(id) {
    if (!this._eventEls) return;
    this._eventEls.forEach((el) => el.classList.remove('fc-event-focus'));
    const el = this._eventEls.get(id);
    if (el) {
      el.classList.add('fc-event-focus');
      el.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  },
  _gotoFocus(all, focusId) {
    const focus = all.find(ev => String(ev.id) === String(focusId));
    if (focus && focus.start) this.calendar.gotoDate(focus.start);
  }
};

Hooks.BarChart = {
  mounted() {
    if (!(window.Chart && this.el)) { console.error("Chart.js not loaded"); return; }
    this._ensureSize();
    const cfg = this._parse();
    const ctx = this.el.getContext('2d');
    this.chart = new Chart(ctx, this._buildConfig(cfg));
    const parent = this.el.parentElement;
    if (parent && 'ResizeObserver' in window) {
      this._ro = new ResizeObserver(() => { this._ensureSize(); this.chart && this.chart.resize(); });
      this._ro.observe(parent);
    } else {
      this._onResize = () => { this._ensureSize(); this.chart && this.chart.resize(); };
      window.addEventListener('resize', this._onResize);
    }
  },
  updated() {
    if (!this.chart) return;
    this._ensureSize();
    const cfg = this._parse();
    this.chart.data.labels = cfg.labels || [];
    this.chart.data.datasets = (cfg.datasets || []).map(ds => this._normalizeDataset(ds));
    this.chart.update();
  },
  destroyed() {
    if (this._ro) this._ro.disconnect();
    if (this._onResize) window.removeEventListener('resize', this._onResize);
    if (this.chart) this.chart.destroy();
  },
  _ensureSize() {
    const parent = this.el.parentElement;
    if (!parent) return;
    const rect = parent.getBoundingClientRect();
    if (rect.width && rect.height) { this.el.width = rect.width; this.el.height = rect.height; }
  },
  _parse() { try { return JSON.parse(this.el.dataset.chart || '{}'); } catch (_e) { return {}; } },
  _buildConfig(cfg) {
    return {
      type: 'bar',
      data: { labels: cfg.labels || [], datasets: (cfg.datasets || []).map(ds => this._normalizeDataset(ds)) },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: 'index', intersect: false },
        plugins: { legend: { display: true, position: 'bottom' }, tooltip: { enabled: true } },
        scales: { x: { grid: { display: true } }, y: { grid: { display: true }, beginAtZero: true } }
      }
    };
  },
  _normalizeDataset(ds) {
    return Object.assign({ label: ds.label || '', data: ds.data || [], backgroundColor: ds.backgroundColor || 'rgba(59,130,246,0.5)' }, ds);
  }
};

Hooks.LineChart = {
  mounted() {
    if (!(window.Chart && this.el)) { console.error("Chart.js not loaded"); return; }
    this._ensureSize();
    const cfg = this._parse();
    const ctx = this.el.getContext('2d');
    this.chart = new Chart(ctx, this._buildConfig(cfg));
    // Watch for container resize
    const parent = this.el.parentElement;
    if (parent && 'ResizeObserver' in window) {
      this._ro = new ResizeObserver(() => {
        this._ensureSize();
        this.chart && this.chart.resize();
      });
      this._ro.observe(parent);
    } else {
      this._onResize = () => { this._ensureSize(); this.chart && this.chart.resize(); };
      window.addEventListener('resize', this._onResize);
    }
  },
  updated() {
    if (!this.chart) return;
    this._ensureSize();
    const cfg = this._parse();
    this.chart.data.labels = cfg.labels || [];
    this.chart.data.datasets = (cfg.datasets || []).map(ds => this._normalizeDataset(ds));
    this.chart.update();
  },
  destroyed() {
    if (this._ro) this._ro.disconnect();
    if (this._onResize) window.removeEventListener('resize', this._onResize);
    if (this.chart) this.chart.destroy();
  },
  _ensureSize() {
    const parent = this.el.parentElement;
    if (!parent) return;
    const rect = parent.getBoundingClientRect();
    if (rect.width && rect.height) {
      this.el.width = rect.width;
      this.el.height = rect.height;
    }
  },
  _parse() {
    try { return JSON.parse(this.el.dataset.chart || '{}'); } catch (_e) { return {}; }
  },
  _buildConfig(cfg) {
    return {
      type: 'line',
      data: {
        labels: cfg.labels || [],
        datasets: (cfg.datasets || []).map(ds => this._normalizeDataset(ds))
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: 'index', intersect: false },
        plugins: {
          legend: { display: true, position: 'bottom' },
          tooltip: { enabled: true }
        },
        scales: {
          x: { grid: { display: true } },
          y: { grid: { display: true }, beginAtZero: true }
        }
      }
    };
  },
  _normalizeDataset(ds) {
    return Object.assign({
      label: ds.label || '',
      data: ds.data || [],
      borderColor: ds.borderColor || '#3b82f6',
      backgroundColor: ds.backgroundColor || 'rgba(59,130,246,0.2)',
      borderWidth: ds.borderWidth || 2,
      tension: ds.tension ?? 0.4,
      pointRadius: ds.pointRadius ?? 2,
      fill: ds.fill ?? false
    }, ds);
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

