@propertyWrapper
struct WeakArray<T> {
    private struct WeakReference {
        var unbox: T? { instance as? T }
        private weak var instance: AnyObject?
        init(_ instance: T) {
            self.instance = instance as AnyObject
        }
    }
    
    public var wrappedValue: [T] {
        get { weakArray.compactMap { $0.unbox } }
        set { weakArray = newValue.map { WeakReference($0) } }
    }
    
    private var weakArray: [WeakReference]
    
    init(wrappedValue: [T]) {
        weakArray = wrappedValue.map { WeakReference($0) }
    }
}
