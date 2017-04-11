public with sharing class PushPriceChangeNotification {

     @InvocableMethod(label='Push Price Change Notification')
    public static void pushNotification(List<Id> propertyId) {
        Id propId = propertyId[0]; // If bulk, only post first to avoid spamming
        System.debug('Price updated on property id '+propId);
        Property__c property = [SELECT Name, Picture__c, Price__c from Property__c WHERE Id=:propId];
        String message = property.Name + '. New Price: $' + property.Price__c.setScale(0).format();

        Set<String> userIds = new Set<String>();

        List<Favorite__c> favorites = [SELECT user__c, user__r.Name from favorite__c WHERE property__c=:propId AND User__c != null];
        for (Favorite__c favorite : favorites) {
            userIds.add(favorite.user__c);
        }

      //universal notification service
         Messaging.PushNotification msg = new Messaging.PushNotification();


         String title = 'Price Changed to $'+property.Price__c.setScale(0).format();
         String subtitle = property.Name;
         String body = 'Heads up! The list price on a property you favorited has just been reduced.';
         String imageUrl = property.Picture__c;
         Map<String, Object> payload = RichMediaPushNotification.createMutablePayload(title,subtitle,body,imageUrl);
         msg.setPayload(payload);
        msg.send('DreamhouseNativeMobile', userIds);



    }
}
