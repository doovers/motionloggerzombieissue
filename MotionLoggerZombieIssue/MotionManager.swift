//
//  MotionManager.swift
//  MotionLoggerZombieIssue
//
//  Created by Colm Du Ve on 10/12/2016.
//  Copyright © 2016 dooversoft. All rights reserved.
//

import CoreMotion
import CoreLocation
import CoreData

class log {
    class func error(_ object: Any) {
        print(object)
    }
}

struct MotionDataRecord {
    var timestamp: TimeInterval = 0
    var location: CLLocation?
    var heading: CLHeading?
    var motionAttitudeReferenceFrame: CMAttitudeReferenceFrame = .xTrueNorthZVertical
    var deviceMotion: CMDeviceMotion?
    var altimeter: CMAltitudeData?
    var accelerometer: CMAccelerometerData?
    var gyro: CMGyroData?
    var magnetometer: CMMagnetometerData?
}

class MotionManager: NSObject {
    static let shared = MotionManager()
    private override init() {}
    
    // MARK: - Class Variables
    
    private let motionManager = CMMotionManager()
    
    fileprivate lazy var locationManager: CLLocationManager = {
        var locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 10.0
        return locationManager
    }()
    
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "MotionQueue"
        queue.qualityOfService = .utility
        return queue
    }()
    
    fileprivate var motionDataRecord = MotionDataRecord()
    
    private var attitudeReferenceFrame: CMAttitudeReferenceFrame = .xTrueNorthZVertical
    
    var interval: TimeInterval = 0.01
    var startTime: TimeInterval?
    
    // MARK: - Class Functions
    
    func start() {
        startTime = Date().timeIntervalSince1970
        startDeviceMotion()
        startAccelerometer()
        startGyroscope()
        startMagnetometer()
        startCoreLocation()
    }
    
    func startCoreLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse, .restricted, .denied:
            break
        }
    }
    
    func startAccelerometer() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = interval
            motionManager.startAccelerometerUpdates(to: queue) { (data, error) in
                if error != nil {
                    log.error("Accelerometer Error: \(error!)")
                }
                guard let data = data else { return }
                self.motionDataRecord.accelerometer = data
            }
        } else {
            log.error("The accelerometer is not available")
        }
        
    }
    
    func startGyroscope() {
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = interval
            motionManager.startGyroUpdates(to: queue) { (data, error) in
                if error != nil {
                    log.error("Gyroscope Error: \(error!)")
                }
                guard let data = data else { return }
                self.motionDataRecord.gyro = data
            }
        } else {
            log.error("The gyroscope is not available")
        }
    }
    
    func startMagnetometer() {
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = interval
            motionManager.startMagnetometerUpdates(to: queue) { (data, error) in
                if error != nil {
                    log.error("Magnetometer Error: \(error!)")
                }
                guard let data = data else { return }
                self.motionDataRecord.magnetometer = data
            }
        } else {
            log.error("The magnetometer is not available")
        }
    }
    
    func startDeviceMotion() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = interval
            motionManager.startDeviceMotionUpdates(using: attitudeReferenceFrame, to: queue) { (data, error) in
                if error != nil {
                    log.error("Device Motion Error: \(error!)")
                }
                guard let data = data else { return }
                self.motionDataRecord.deviceMotion = data
                self.motionDataRecord.timestamp = Date().timeIntervalSince1970
                self.handleMotionUpdate()
            }
        } else {
            log.error("Device motion is not available")
        }
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopDeviceMotionUpdates()
    }
    
    func handleMotionUpdate() {
        print(motionDataRecord)
    }
    
}

// MARK: - Location Manager Delegate
extension MotionManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        motionDataRecord.location = location
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        motionDataRecord.heading = newHeading
    }
    
}


