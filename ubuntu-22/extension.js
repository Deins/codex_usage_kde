const {Clutter, Gio, GLib, GObject, St} = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const ExtensionUtils = imports.misc.extensionUtils;

const REFRESH_SECONDS = 300;

const Indicator = GObject.registerClass(
class Indicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'Codex Usage');

        this._panelLabel = new St.Label({
            text: 'Codex …',
            y_align: Clutter.ActorAlign.CENTER,
        });
        this.add_child(this._panelLabel);

        this._primary = this._addRow('Usage: —');
        this._secondary = this._addRow('Additional usage: —');
        this._primaryReset = this._addRow('Resets in: —');
        this._secondaryReset = this._addRow('Additional reset: —');
        this._allowance = this._addRow('Remaining allowance: —');
        this._credits = this._addRow('Credits: —');
        this._plan = this._addRow('Plan: —');
        this._status = this._addRow('Loading…');
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        const refresh = new PopupMenu.PopupMenuItem('Refresh now');
        refresh.connect('activate', () => this._refresh());
        this.menu.addMenuItem(refresh);

        this._cancellable = new Gio.Cancellable();
        this._loading = false;
        this._refresh();
        this._timerId = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT,
            REFRESH_SECONDS,
            () => {
                this._refresh();
                return GLib.SOURCE_CONTINUE;
            });
    }

    _addRow(text) {
        const item = new PopupMenu.PopupMenuItem(text, {
            reactive: false,
            can_focus: false,
        });
        this.menu.addMenuItem(item);
        return item;
    }

    _refresh() {
        if (this._loading)
            return;

        this._loading = true;
        this._status.label.set_text('Loading…');
        const script = `${ExtensionUtils.getCurrentExtension().path}/codex_usage.bash`;
        const process = Gio.Subprocess.new(
            ['/usr/bin/bash', script],
            Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE);

        process.communicate_utf8_async(null, this._cancellable, (source, result) => {
            try {
                const [, stdout, stderr] = source.communicate_utf8_finish(result);
                if (!source.get_successful())
                    throw new Error(stderr.trim() || 'Codex usage request failed');
                this._show(JSON.parse(stdout));
            } catch (error) {
                if (!this._cancellable.is_cancelled()) {
                    this._panelLabel.set_text('Codex !!');
                    this._status.label.set_text(error.message);
                }
            } finally {
                this._loading = false;
            }
        });
    }

    _show(response) {
        if (response.error)
            throw new Error(response.error.message || 'Codex App Server returned an error');

        let limits = response.result && response.result.rateLimits;
        if (!limits && response.result && response.result.rateLimitsByLimitId) {
            const ids = Object.keys(response.result.rateLimitsByLimitId);
            limits = ids.length ? response.result.rateLimitsByLimitId[ids[0]] : null;
        }
        if (!limits)
            throw new Error('No rate-limit information was returned');

        const primary = limits.primary || {};
        const secondary = limits.secondary || {};
        const primaryUsed = Math.round(primary.usedPercent || 0);
        const secondaryUsed = Math.round(secondary.usedPercent || 0);

        this._panelLabel.set_text(`Codex ${primaryUsed}%`);
        const primaryName = this._windowName(primary.windowDurationMins);
        const secondaryName = this._windowName(secondary.windowDurationMins);
        this._primary.label.set_text(`${primaryName} usage: ${primaryUsed}%`);
        this._primaryReset.label.set_text(`${primaryName} resets in: ${this._timeLeft(primary.resetsAt)}`);
        this._secondary.label.set_text(`${secondaryName} usage: ${secondaryUsed}%`);
        this._secondaryReset.label.set_text(`${secondaryName} resets in: ${this._timeLeft(secondary.resetsAt)}`);
        this._secondary.visible = Boolean(secondary.windowDurationMins);
        this._secondaryReset.visible = Boolean(secondary.windowDurationMins);
        const allowance = this._remainingPerDay(primary, secondary);
        this._allowance.label.set_text(`Remaining allowance: ${allowance === null ? '—' : `${allowance}% / day`}`);
        const balance = limits.credits && parseFloat(limits.credits.balance);
        this._credits.label.set_text(`Credits: ${Number.isFinite(balance) ? balance.toFixed(1) : '—'}`);
        this._plan.label.set_text(`Plan: ${limits.planType || '—'}`);
        this._status.label.set_text('Updated just now');
    }

    _windowName(minutes) {
        if (minutes === 10080)
            return 'Weekly';
        if (minutes && minutes % 60 === 0)
            return `${minutes / 60}-hour`;
        return minutes ? `${minutes}-minute` : 'Current';
    }

    _timeLeft(timestamp) {
        if (!timestamp)
            return '—';
        const seconds = timestamp - Math.floor(Date.now() / 1000);
        if (seconds <= 0)
            return 'now';
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor(seconds % 86400 / 3600);
        const minutes = Math.floor(seconds % 3600 / 60);
        if (days)
            return `${days}d ${hours}h`;
        if (hours)
            return `${hours}h ${minutes}m`;
        return `${Math.max(1, minutes)}m`;
    }

    _remainingPerDay(primary, secondary) {
        const limit = secondary.windowDurationMins >= 1440 ? secondary : primary;
        if (!limit.resetsAt || limit.windowDurationMins < 1440)
            return null;
        const daysLeft = (limit.resetsAt - Date.now() / 1000) / 86400;
        return daysLeft > 0
            ? ((100 - (limit.usedPercent || 0)) / daysLeft).toFixed(1)
            : null;
    }

    destroy() {
        if (this._timerId)
            GLib.source_remove(this._timerId);
        this._cancellable.cancel();
        super.destroy();
    }
});

let indicator = null;

function enable() {
    indicator = new Indicator();
    Main.panel.addToStatusArea('codex-usage', indicator);
}

function disable() {
    indicator.destroy();
    indicator = null;
}
