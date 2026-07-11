import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property var usageData: null
    property string errorString: ""
    property bool loading: false

    readonly property int primaryUsed: usageData ? (usageData.primary_used_percent ?? 0) : 0
    readonly property int secondaryUsed: usageData ? (usageData.secondary_used_percent ?? 0) : 0
    readonly property bool rateLimitReached: usageData ? (usageData.rate_limit_reached !== null && usageData.rate_limit_reached !== undefined) : false
    readonly property string planType: usageData ? (usageData.plan_type ?? "") : ""

    readonly property color primaryColor: rateLimitReached ? Kirigami.Theme.negativeTextColor :
                                       primaryUsed >= 80 ? Kirigami.Theme.neutralTextColor :
                                       Kirigami.Theme.highlightColor
    readonly property color secondaryColor: Kirigami.Theme.positiveTextColor

    Plasmoid.title: i18n("Codex Usage")
    Plasmoid.icon: "view-statistics"
    toolTipMainText: usageData ? i18n("Codex: %1%", primaryUsed) : i18n("Codex Usage")
    toolTipSubText: usageData ? i18n("Weekly: %1%\nPlan: %2", secondaryUsed, planType) : ""

    readonly property string scriptPath: {
        var url = Qt.resolvedUrl("../scripts/codex_usage.bash")
        return url.toString().replace("file://", "")
    }

    readonly property string fullCommand: {
        var path = plasmoid.configuration.codexBinaryPath || ""
        var cmd = "bash " + scriptPath
        if (path) {
            cmd = "CODEX_BIN=" + shellQuote(path) + " " + cmd
        }
        return cmd
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'"
    }

    function usageFromResponse(response) {
        if (response.error) {
            throw new Error(response.error.message || i18n("Codex App Server returned an error."))
        }

        var limits = response.result && response.result.rateLimits
        if (!limits && response.result && response.result.rateLimitsByLimitId) {
            var limitIds = Object.keys(response.result.rateLimitsByLimitId)
            limits = limitIds.length > 0 ? response.result.rateLimitsByLimitId[limitIds[0]] : null
        }
        if (!limits) {
            throw new Error(i18n("No rate-limit information was returned."))
        }

        return {
            primary_used_percent: limits.primary ? limits.primary.usedPercent : 0,
            primary_window_minutes: limits.primary ? limits.primary.windowDurationMins : 0,
            primary_resets_at: limits.primary ? limits.primary.resetsAt : null,
            secondary_used_percent: limits.secondary ? limits.secondary.usedPercent : 0,
            secondary_window_minutes: limits.secondary ? limits.secondary.windowDurationMins : 0,
            secondary_resets_at: limits.secondary ? limits.secondary.resetsAt : null,
            plan_type: limits.planType || "",
            rate_limit_reached: limits.rateLimitReachedType,
            credits_balance: limits.credits ? limits.credits.balance : null,
            credits_unlimited: limits.credits ? limits.credits.unlimited : false
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            var exitCode = data["exit code"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            root.loading = false
            if (parseInt(exitCode) !== 0) {
                root.errorString = stderr.trim() || i18n("Failed to fetch Codex usage (exit code %1).", exitCode)
                root.usageData = null
            } else {
                try {
                    root.usageData = root.usageFromResponse(JSON.parse(stdout))
                    root.errorString = ""
                } catch (e) {
                    root.errorString = i18n("Failed to parse Codex usage response.")
                    root.usageData = null
                }
            }
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            if (cmd) connectSource(cmd)
        }
    }

    function refresh() {
        root.loading = true
        executable.exec(fullCommand)
    }

    Timer {
        id: refreshTimer
        interval: Math.max(30, plasmoid.configuration.refreshInterval) * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    compactRepresentation: CompactRep {}
    fullRepresentation: FullRep {}
    preferredRepresentation: compactRepresentation

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh Now")
            icon.name: "view-refresh"
            onTriggered: root.refresh()
        }
    ]
}
