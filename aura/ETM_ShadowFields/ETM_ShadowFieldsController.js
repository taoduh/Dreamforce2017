({
	updateOne : function(component, event, helper) {
        // NOTE: if you want to have a lookup for account ID instead of a test input, check out this post
        // https://developer.salesforce.com/blogs/developer-relations/2015/06/salesforce-lightning-inputlookup-missing-component.html

        var accountId = component.get("v.accountId");
        console.log("in updateOne for " + accountId);

        // define controller method
		var action = component.get("c.updateOneAccount");
		action.setParams({
			"strAccountId" : accountId
		});

	    // define controller method callback
    	action.setCallback(this, function(response) {
        	var state = response.getState();
        	if (state === "SUCCESS") {
            	console.log("updated " + accountId);
        	}
        	else {
            	console.log("Failed with state: " + state);
        	}
    	});

	    // call controller method
    	$A.enqueueAction(action);
    },
	updateAll : function(component, event, helper) {
        console.log("in updateAll");

        // define controller method
		var action = component.get("c.updateAllAccounts");

	    // define controller method callback
    	action.setCallback(this, function(response) {
        	var state = response.getState();
        	if (state === "SUCCESS") {
            	console.log("batch update begun");
        	}
        	else {
            	console.log("Failed with state: " + state);
        	}
    	});

	    // call controller method
    	$A.enqueueAction(action);
    }
})
