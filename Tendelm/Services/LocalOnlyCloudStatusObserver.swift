import Observation
import TendelmCore
@MainActor @Observable
final class LocalOnlyCloudStatusObserver: CloudAccountStatusObserving {
    var status: CloudAccountStatus { .noAccount }
    var syncHealth: CloudSyncHealth { .unknown }
    func refresh() async {}
}
