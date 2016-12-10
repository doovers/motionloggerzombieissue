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

struct Floor {
    var level: Int
}

struct Location {
    var timestamp: Date
    var coordinate: CLLocationCoordinate2D
    var altitude: CLLocationDistance
    var floor: Floor?
    var horizontalAccuracy: CLLocationAccuracy
    var verticalAccuracy: CLLocationAccuracy
    var speed: CLLocationSpeed
    var course: CLLocationDirection
}

struct Heading {
    var timestamp: Date
    var magneticHeading: CLLocationDirection
    var trueHeading: CLLocationDirection
    var headingAccuracy: CLLocationDirection
    var x: CLHeadingComponentValue
    var y: CLHeadingComponentValue
    var z: CLHeadingComponentValue
}

struct Attitude {
    var roll: Double
    var pitch: Double
    var yaw: Double
    var rotationMatrix: CMRotationMatrix
    var quaternion: CMQuaternion
}

struct DeviceMotion {
    var timestamp: TimeInterval
    var attitude: Attitude
    var rotationRate: CMRotationRate
    var gravity: CMAcceleration
    var userAcceleration: CMAcceleration
    var magneticField: CMCalibratedMagneticField
}

struct AltitudeData {
    var timestamp: TimeInterval
    var relativeAltitude: NSNumber
    var pressure: NSNumber
}

struct AccelerometerData {
    var timestamp: TimeInterval
    var acceleration: CMAcceleration
}

struct GyroData {
    var timestamp: TimeInterval
    var rotationRate: CMRotationRate
}

struct MagnetometerData {
    var timestamp: TimeInterval
    var magneticField: CMMagneticField
}

struct MotionDataRecord {
    var timestamp: TimeInterval = 0
    var location: Location?
    var heading: Heading?
    var motionAttitudeReferenceFrame: CMAttitudeReferenceFrame = .xTrueNorthZVertical
    var deviceMotion: DeviceMotion?
    var altimeter: AltitudeData?
    var accelerometer: AccelerometerData?
    var gyro: GyroData?
    var magnetometer: MagnetometerData?
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
                let accelerometerData = AccelerometerData(timestamp: data.timestamp, acceleration: data.acceleration)
                self.motionDataRecord.accelerometer = accelerometerData
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
                let gyroData = GyroData(timestamp: data.timestamp, rotationRate: data.rotationRate)
                self.motionDataRecord.gyro = gyroData
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
                let magnetometerData = MagnetometerData(timestamp: data.timestamp, magneticField: data.magneticField)
                self.motionDataRecord.magnetometer = magnetometerData
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
                let attitude = Attitude(roll: data.attitude.roll, pitch: data.attitude.pitch, yaw: data.attitude.yaw, rotationMatrix: data.attitude.rotationMatrix, quaternion: data.attitude.quaternion)
                let deviceMotion = DeviceMotion(timestamp: data.timestamp, attitude: attitude, rotationRate: data.rotationRate, gravity: data.gravity, userAcceleration: data.userAcceleration, magneticField: data.magneticField)
                self.motionDataRecord.deviceMotion = deviceMotion
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
        var floor: Floor?
        if let clFloor = location.floor {
            floor = Floor(level: clFloor.level)
        }
        let locationData = Location(timestamp: location.timestamp, coordinate: location.coordinate, altitude: location.altitude, floor: floor, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, speed: location.speed, course: location.course)
        motionDataRecord.location = locationData
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = Heading(timestamp: newHeading.timestamp, magneticHeading: newHeading.magneticHeading, trueHeading: newHeading.trueHeading, headingAccuracy: newHeading.headingAccuracy, x: newHeading.x, y: newHeading.y, z: newHeading.z)
        motionDataRecord.heading = heading
    }
    
}


