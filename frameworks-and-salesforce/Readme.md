# Keep Your Code Clean with Custom Frameworks to Encapsulate Salesforce Connectivity
## Introduction
A framework, introduced in Xcode 6 and iOS 8,  is basically a modular collection of code. Frameworks make it easier for developers to encapsulate code for improved re-use within a project, or with other teams, and to promote clean, testable interfaces. I frequently create frameworks as soon as I realize that the code I am writing needs to be shared between targets in my project.

In years past, I rarely created my own frameworks, as most of my projects generally consisted of a single target, or maybe two at the most, within a project. Now, with the rise of the Apple Watch, iMessages, and more, multiple targets is the norm. I now use frameworks all the time. They are an invaluable tool in an iOS developers toolbox.

![](https://github.com/quintonwall/salesforce-tutorials/blob//master/frameworks-and-salesforce/graphics/DreamhouseAnywhere_xcodeproj.png?raw=true)

Connectivity to backends, such as Salesforce, is a common example of logic that is frequently called from multiple parts of my application, and something I generally like to abstract connectivity details from the rest of my app. .This tutorial will demonstrate how you can use Frameworks within your app encapsulate Salesforce data access allowing it to be re-used easily across targets.

## What are we building?
Generally I don’t start with a framework, but as soon as I see the need I refactor my code. In this example, based on the [DreamhouseAnywhere](https://github.com/quintonwall/DreamhouseAnywhere) app, we are going to have both an iPhone app and Apple Watch app. The logic to retrieve property details is common code utilized by both. It’s a great candidate to refactor into a framework.

![](https://github.com/quintonwall/salesforce-tutorials/blob//master/frameworks-and-salesforce/graphics/framework-overview.png?raw=true)



## Creating the DreamhouseKit Framework
Let’s assume you have your project created. Click `File -> New Target` and select `CocoaTouchFramework`, then click `Next`.  On the next screen, give it a name. I’m using `DreamhouseKit`. You can leave everything else with the default settings. One thing to pay attention to though, is the `Embed in Application` dropdown. We will use this later when we want multiple different targets to access our framework. For now though, just leave it to your iOS App target.  When you are done, click `Finish.`

![](https://github.com/quintonwall/salesforce-tutorials/blob/master/frameworks-and-salesforce/graphics/Screenshot_4_22_17__11_18.png?raw=true)

Once you are done, you should have a new Target with a little yellow lunchbox icon.
![](https://github.com/quintonwall/salesforce-tutorials/blob/master/frameworks-and-salesforce/graphics/FrameworkTutorial_xcodeproj.png?raw=true)

Now, it is time to add some code to our framework.

## HelloFramework()
Go ahead and add a new swift file to the DreamhouseKit folder (framework), and call it SalesforceData, then add the following code. Yes, this func is about as basic as it gets, but it will give us a nice simple example of how to call functions within a framework. It also provides the code to create a [Singleton](https://en.wikipedia.org/wiki/Singleton_pattern). I frequently use Singletons to encapsulate backend logic.

Once you have added the code below, build your project to create the framework.

### SalesforceData.swift

```swift
public final class SalesforceData {

    public static let shared = SalesforceData()

    public func helloFramework() -> String {
        return "Hello Framework!"
    }

}
```

### ViewController.swift
Now, from in any other app target, we can call our function. To make it easy, lets just call if from a viewDidLoad func of a ViewController.

The first thing you need to do is import your framework. Add the `import DreamhouseKit` line to your `ViewController`. If Xcode does not autocomplete the name of your framework, it is likely that you did not specific the correct `Embed in Application` target when creating the framework. To fix this, click on the project, select the iOS app target and click the + in the `Embedded Binaries` to add `DreamhouseKit`.

```swift
import UIKit
import DreamhouseKit

class ViewController: UIViewController {
```

With our framework imported, we can get an instance of our Singleton and call our func. If Xcode does not autocomplete as you type, make sure you build (CMD-B) your project to compile to framework

```swift
 override func viewDidLoad() {
        super.viewDidLoad()

        let msg = SalesforceData.shared.helloFramework()
        print(msg)
    }
```

Go ahead and run your project. When the view loads, you should see our `Hello Framework` message. Cool! You’ve just created your first framework.

![](https://github.com/quintonwall/salesforce-tutorials/blob/master/frameworks-and-salesforce/graphics/Main_storyboard.png?raw=true)

## Accessing Salesforce Data & Promises
Our HelloFramework func was a helpful example to help us understand how to create and use frameworks. It’s time to add some real logic. The DreamhouseAnywhere app retrieves property data from Salesforce via functions in the DreamhouseKit framework.

One of the great things about using a framework in your app design is that this pattern also allows you to abstract away how you connect to Salesforce, specifically whether you use the [Salesforce Mobile SDK](https://developer.salesforce.com/page/Mobile_SDK), or another library like [SwiftySalesforce](https://github.com/mike4aday/SwiftlySalesforce).

In this example we are going to use SwiftySalesforce primary because I like to use [Promises](https://github.com/mxcl/PromiseKit) for network calls. Promises provides the ability to perform async calls, greatly improving performance of your app. In our SalesforceData.swift, go ahead and add the following function.

```swift
public func getAllProperties() -> Promise<[Property]> {

        return Promise<[Property]> {
            fulfill, reject in
            first {
                      salesforce.identity()

            }.then { result in
                let soql = "select Address__c, Baths__c, Beds__c, Broker__c, Broker__r.Title__c, Broker__r.Name, Broker__r.Picture__c, City__c, Description__c, Id, Location__c, Name, OwnerId, Picture__c, Price__c, State__c, Thumbnail__c, Title__c, Zip__c, (select id, Property__c from Favorites__r) from Property__c"
                return salesforce.query(soql: soql)
            }.then {
                (result: QueryResult) -> () in
                let properties = result.records.map { Property(dictionary: $0) }
                fulfill(properties)
            }.catch { error in
                reject(error)
            }

        }
    }

```

If you haven’t used Promises before, the syntax might be a little confusing. The most important thing to understand is that promises execute code blocks asynchronously starting with `.first`, followed by x number of `.then` blocks and also include an `.always` block which, as the name says, always gets executed.

Starting with the `.first` block, we are using the SwiftySalesforce function to ensure our user has logged into Salesforce, `then` we perform a SOQL query to fetch data, `then` map the results to an object of type Property.  

The last thing to note here is the func call `fulfill(properties)`. Our func `getAllProperties()` returns a promise, in other words, once getAllProperties finishes communicating with Salesforce, it fulfills the promise of whoever calls this function to return the data.  Remember what your parents taught you -- never break a promise. ;)

Using promises is a little confusing to start with, but persistence really pays off. Your app will perform much more efficiently, and your users will appreciate it.

## Properties object
Keeping true to our design approach of encapsulating backend logic from our app, we don’t want to expose Salesforce field names beyond our DreamhouseKit framework. Instead of returning the JSON results from Salesforce, our promise returns a collection of Property objects.

Aside from keeping our logic separate, I like to use strongly typed objects, to map JSON results (which are always strings, obviously) to specific primitive field types, such as Ints and Doubles.  This saves duplicating logic in your app to translate field types.  Let’s create that now. Right-click the DreamhouseKit folder, and choose `New File -> Swift File`, and call it `Property.swift`. Once you’ve created it, paste in the code below.

You might have noticed that we are using a struct, rather than a class for our Property Object. Structs consume a little less memory than objects, and since we may be creating, and passing around, quite a few instances of the Property object, using structs is a nice performance optimization.


```swift
public struct Property {

    public var id: String = ""
    public var propertyImageURLString = ""
    public var thumbnailImageURLString = ""
    public var isSold: Bool = false
    public var address : Address?
    public var city: String = ""
    public var state: String = ""
    public var description: String = ""
    public var pictureImageURL: String = ""
    public var price:Double  = 0
    public var thumbnailImageURL: String = ""
    public var title: String?
    public var zip: String?
    public var baths: Int = 0
    public var beds: Int = 0
    public var longitude: Double = 0
    public var latitude: Double = 0
    public var isFavorite: Bool = false

    //broker info
    public var brokerId: String = ""
    public var brokerName: String = ""
    public var brokerTitle: String = ""
    public var brokerImageURL: String = ""

    //favorite
    public var favoriteId: String = ""

    //save dictionary representation as we need to pass that to watchOS apps
    public var asDictionary: [String : Any]?

    public init() {}


    //take JSON from Salesforce REST API and convert to strongly typed object
    public init(dictionary: [String: Any]) {
        asDictionary = dictionary

        for(key, value) in dictionary {
            switch key.lowercased() {
                case "id":
                    self.id = (value as? String)!
                case "title__c":
                    self.title = (value as? String)!
                case "broker__c":
                    self.brokerId = (value as? String)!
                case "broker__r":
                    var payload: [String: Any] = value as! [String : Any]
                    for (key, value) in payload {
                        switch key.lowercased() {
                           case "title__c":
                            self.brokerTitle = (value as? String)!
                        case "name":
                            self.brokerName = (value as? String)!
                        case "picture__c":
                            self.brokerImageURL = (value as? String)!
                        default:
                            continue
                        }
                    }
                case "city__c":
                    self.city = (value as? String)!
                case "favorites__r":
                    self.isFavorite = true
                case "location__c":
                    var payload: [String: Any] = value as! [String : Any]
                    for (key, value) in payload {
                        switch key.lowercased() {
                            case "longitude":
                                self.longitude = (value as? Double)!
                        case "latitude":
                            self.latitude = (value as? Double)!
                        default:
                            continue
                        }
                    }
                case "baths__c":
                    self.baths = (value as? Int)!
                case "beds__c":
                    self.beds = (value as? Int)!
                case "description__c":
                    self.description = (value as? String)!
                case "picture__c":
                    self.propertyImageURLString = (value as? String)!
                case "thumbnail__c":
                    self.thumbnailImageURLString = (value as? String)!
                case "price__c":
                    self.price = (value as? Double)!
                default:
                    continue
            }
        }
    }

```

That’s it! We’ve created our `Property` object which maps Salesforce fields to strongly typed variables, and fulfilled our `promise` to our app by returning a collection of Property objects to anyone who called `getAllProperties()`. Our framework is nice and encapsulated from the rest of our app, can be easily re-used from multiple targets, and can include clean unit tests (which I skipped in this tutorial to help us focus on the framework and accessing Salesforce data instead.) to ensure things continue to work as designed.

## Calling getAllProperties() from our app
We already saw how to call a framework function in our `HelloFramework` example. Now, let’s take a quick look at how we handle a call to promise in our framework. Go ahead and add the following func to your `ViewController`

```swift
func fetchProperties() {
        first {
           SalesforceData.shared.getAllProperties()    
        }.then {
                (results) -> () in
                self.properties = results
                self.tableView.reloadData()
        }.catch {
         (error) -> () in
            print("error: \(error)")  
        }
    }
```

The first thing you will notice is how clean our code is. This is the great thing about encapsulating your code with framworks. In this example, taken from [PropertiesTableViewController](https://github.com/quintonwall/DreamhouseAnywhere/blob/master/DreamhouseAnywhere/DreamhouseAnywhere/PropertiesTableViewController.swift) in the DreamhouseAnywhere app, we fetch our data and bind it to a table for display.

If you check out the `PropertiesTableViewController`, you can see how we utilize the Property object to make data binding super easy.

```swift
 override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PropertiesTableViewCell

        let property : Property = properties[indexPath.row]
        cell.property = property
        cell.propertyImageURLString = property.propertyImageURLString
        cell.numBathrooms.text = "\(property.baths)"
        cell.price.text = property.price.currencyString()
        cell.numBedrooms.text = "\(property.bedrooms)"

        return cell
    }

```


## Summary
In this tutorial, we looked at how creating frameworks can greatly enhance the reusability of your code, especially in projects that have multiple targets. In addition, we briefly introduced Promises as a way to call Salesforce, and your framework functions, in an async way for improved app performance.  Some of the code snippets included in the tutorial rely on other parts of your app to be fully configured (setting up SwiftlySalesforce for example). For a complete end-to-end sample, check out the [DreamhouseAnywhere](https://github.com/quintonwall/DreamhouseAnywhere) app.

## Found an Error? Want to Contribute?
This tutorial is a github repo. If you find an error, or have something to add, please [create a pull request](https://github.com/quintonwall/salesforce-tutorials/pulls).

#work
