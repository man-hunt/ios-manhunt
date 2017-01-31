import UIKit
import CoreLocation
import CoreMotion
import MapKit
import AVFoundation

class ViewController: UIViewController, CLLocationManagerDelegate,MKMapViewDelegate {
    
    @IBOutlet weak var startView: UIView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var map: MKMapView!
    
    var locationManager:CLLocationManager!
    var user_id: String!
    var userName: String!
    var count: Int!
    var lat: Double!
    var lon: Double!
    var heading: Double!
    var users : [[String: Any]]!
    var me : [String: Any]!
    var usersTimer : Timer!
    var selfTimer : Timer!
    var death : Int!
    
    var player:AVAudioPlayer?
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var killsLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        users = [[String:Any]]()
        me = [String:Any]()
        usersTimer = Timer()
        selfTimer  = Timer()
        timeLabel.alpha = 0
        killsLabel.alpha = 0
        nameLabel.alpha = 0
        map.alpha = 0
        user_id = String()
        userName = String()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        death = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        determineMyCurrentLocation()
    }
    
    let regionRadius: CLLocationDistance = 1000
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        map.setRegion(coordinateRegion, animated: true)
    }
    
    func status(stat : Int, name : String){
        if stat == 0 {
            DispatchQueue.main.async {
            self.statusLabel.text = ""
            self.statusLabel.textColor = UIColor.green
            }
        }else if stat == 1{
            DispatchQueue.main.async {
            self.statusLabel.text = "\(name) is in range"
            self.statusLabel.textColor = UIColor.blue
            }
        }else if stat == 2{
            DispatchQueue.main.async {
            self.statusLabel.text = "Attacking \(name)!"
            self.statusLabel.textColor = UIColor.green
                
            }
            let systemSoundID: SystemSoundID = 1011
            AudioServicesPlaySystemSound (systemSoundID)
        }else if stat == 3{
            DispatchQueue.main.async {
            self.statusLabel.text = "\(name) is attacking you"
            self.statusLabel.textColor = UIColor.red
            }
        }else if stat == 4{
            DispatchQueue.main.async {
            self.statusLabel.text = "\(name) killed you"
            self.statusLabel.textColor = UIColor.red
            }
        }
    }
    func update(){
        count = count + 1
        
        if count % 2 > 0{
            _ = apiGET(params: ["":""])
        }else{
            _ = apiPUT(params: ["id":user_id,"loc":["lat":lat,"long":lon,"dir":heading]])
        }
    }
    
    func updateUsers(){
        if death == 1{
            return
        }
        
        let allAnnotations = self.map.annotations
        self.map.removeAnnotations(allAnnotations)
        var arr = [MKAnnotation]()
        
        let medead = me["isDead"] as! Bool
        if medead{
            death = 1
            print("you're dead")
            self.status(stat: 4,name: "")
            self.endGame()
            return
        }
        
        if let kills = me["killed"] as? [[String:Any]]{
            DispatchQueue.main.async {
                self.killsLabel.text = "\(kills.count) kills"
            }
        }
       
        let credits = lround(me["credits"] as! Double)
        DispatchQueue.main.async {
            self.timeLabel.text = "\(credits) credits"
        }
        
        if let locked = me["lockedOnBy"] as? [String:Any]{
            print("locked alert!!")
            self.status(stat: 3,name: locked["name"] as! String)
        }else{
            if let target = me["target"] as? [String:Any] {
                let named = target["name"] as! String
                status(stat: 2,name: named)
            }else{
                status(stat: 0,name: "")
            }
        }
        
        for user in users{
            let userr = user["user"] as! [String: Any]
            let dead = userr["isDead"] as! Bool
            
            let kills = userr["killed"] as! [String]
            
            let credits = lround(userr["credits"] as! Double)
            let name = userr["name"] as! String
            let idd = userr["_id"] as! String
            
            if true==true{
                let loc = userr["loc"] as! [String: Any]
                let coords = loc["coordinates"] as! [Double]
                
                let plot = MapPlot()
                plot.coordinate = CLLocationCoordinate2DMake(coords[1] as CLLocationDegrees, coords[0] as CLLocationDegrees)
                if dead && (user_id != idd){
                    plot.images = "dead"
                    plot.title = name
                    plot.subtitle = "\(kills.count) kills/\(credits) credits"
                    
                    arr.append(plot)
                }else if (user_id != idd){
                    plot.images = "alive"
                    plot.title = name
                    plot.subtitle = "\(kills.count) kills/\(credits) credits"
                    
                    arr.append(plot)
                }else{
                    
                }
            }
                //DispatchQueue.main.async {
                self.map.addAnnotations(arr)
                for ar in arr{
                    self.map.selectAnnotation(ar, animated: true)
                }
               //}
            }
    }

    func endGame(){
        if self.usersTimer != nil{
           self.usersTimer.invalidate()
        }
        if self.selfTimer != nil{
           self.selfTimer.invalidate()
        }

        self.map.removeFromSuperview()
        
        DispatchQueue.main.async {
        let url = Bundle.main.url(forResource: "Rick Astley - Never Gonna Give You Up", withExtension: "mp3")!
        
        do {
            self.player = try AVAudioPlayer(contentsOf: url)
            guard let player = self.player else { return }
            player.prepareToPlay()
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
        
        let imageName = "rick"
        let image = UIImage(named: imageName)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.view.addSubview(imageView)
        }
    }
    
    @IBAction func startGame(_ sender: Any) {
        userName = usernameField.text
        usernameField.resignFirstResponder()
        
        _ = apiPOST(params: ["name":userName,"ble":""])
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { () -> Void in
            self.startView.alpha = 0
            self.usernameField.alpha = 0
        },completion: { (finished: Bool) in
        })
        
        count = 0

        nameLabel.text = userName 
        timeLabel.text = "0 credits"
        killsLabel.text = "0 kills"
        map.alpha = 1
        timeLabel.alpha = 1
        killsLabel.alpha = 1
        nameLabel.alpha = 1
        
        self.map.delegate = self
        self.map.showsUserLocation = true
        self.map.isRotateEnabled = true
        self.map.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
    
        selfTimer = Timer.scheduledTimer(timeInterval: 1,
                             target: self,
                             selector: #selector(self.update),
                             userInfo: nil,
                             repeats: true)
    
        usersTimer = Timer.scheduledTimer(timeInterval: 2,
                             target: self,
                             selector: #selector(self.updateUsers),
                             userInfo: nil,
                             repeats: true)
    }

    //API
    func apiGET(params: [String: Any]){
        let ur = URL(string: "http://107.170.217.16:3000/v1/users/\(user_id!)")!
       
        var request = URLRequest(url: ur)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
       
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
           self.me = responseJSON["user"] as? [String:Any]
            self.users = responseJSON["nearby"] as? [[String:Any]]
            }
        }
        task.resume()
    }
    
    func apiPUT(params: [String: Any]){
        let ur = URL(string: "http://107.170.217.16:3000/v1/users")!
        
        var request = URLRequest(url: ur)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
           let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
           // if let responseJSON = responseJSON as? [String: Any] {
                
           // }
        }
        task.resume()
    }
    
    func apiPOST(params: [String: Any]){
        let ur = URL(string: "http://107.170.217.16:3000/v1/users")!
        
        var request = URLRequest(url: ur)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                    self.user_id = responseJSON["_id"] as! String
            }
        }
        task.resume()
    }

    //location
    func determineMyCurrentLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
    }
    
    //delegate functions
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        lat = userLocation.coordinate.latitude
        lon = userLocation.coordinate.longitude
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.magneticHeading
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation === mapView.userLocation) {
          return nil
        }
        let reuseIdentifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        let customAn = annotation as! MapPlot
        if customAn.images == "dead" {
            let pinImage = UIImage(named: "dead.png")
            let size = CGSize(width: 50, height: 50)
            UIGraphicsBeginImageContext(size)
            pinImage!.draw(in: CGRect(x:0,y:0,width:size.width,height:size.height))
            
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            annotationView?.image = resizedImage
        }else{
            let pinImage = UIImage(named: "manhunt_new.png")
            let size = CGSize(width: 50, height: 50)
            UIGraphicsBeginImageContext(size)
            pinImage!.draw(in: CGRect(x:0,y:0,width:size.width,height:size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            annotationView?.image = resizedImage
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool){
        if mapView.userTrackingMode != MKUserTrackingMode.followWithHeading{
            mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
            mapView.isRotateEnabled = true
        }
    }
}
