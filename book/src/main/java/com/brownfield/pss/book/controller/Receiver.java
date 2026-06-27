package com.brownfield.pss.book.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

import com.brownfield.pss.book.component.BookingComponent;
import com.brownfield.pss.book.component.BookingStatus;

// ActiveMQ: listens on CheckINQ for check-in events sent by the checkin service.
// bookingId arrives as a JMS TextMessage (String) and is parsed to long to avoid ObjectMessage trust configuration.
@Component
public class Receiver {

	BookingComponent bookingComponent;

	@Autowired
	public Receiver(BookingComponent bookingComponent) {
		this.bookingComponent = bookingComponent;
	}

	@JmsListener(destination = "CheckINQ")
	public void processMessage(String bookingIDStr) {
		long bookingID = Long.parseLong(bookingIDStr);
		System.out.println("Check-in event received for booking: " + bookingID);
		bookingComponent.updateStatus(BookingStatus.CHECKED_IN, bookingID);
	}
}
