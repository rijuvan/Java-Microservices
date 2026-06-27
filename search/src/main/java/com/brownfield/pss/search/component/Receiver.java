package com.brownfield.pss.search.component;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

// ActiveMQ: listens on SearchQ for booking events sent by the book service.
// The Map payload is received as a JMS MapMessage and converted back to Map<String,Object>
// automatically by Spring's SimpleMessageConverter.
@Component
public class Receiver {

	SearchComponent searchComponent;

	@Autowired
	public Receiver(SearchComponent searchComponent) {
		this.searchComponent = searchComponent;
	}

	@JmsListener(destination = "SearchQ")
	public void processMessage(Map<String, Object> bookingEvent) {
		System.out.println("Booking event received: " + bookingEvent);
		searchComponent.updateInventory(
			(String) bookingEvent.get("FLIGHT_NUMBER"),
			(String) bookingEvent.get("FLIGHT_DATE"),
			(int) bookingEvent.get("NEW_INVENTORY")
		);
	}
}
