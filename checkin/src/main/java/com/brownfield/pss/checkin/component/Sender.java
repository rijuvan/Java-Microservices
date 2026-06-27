package com.brownfield.pss.checkin.component;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

// ActiveMQ: JmsTemplate replaces RabbitMessagingTemplate.
// Sends the bookingId to CheckINQ so the book service can update the booking status to CHECKED_IN.
// Queue is auto-created by the broker on first send — no @Bean Queue declaration needed.
@Component
public class Sender {

	JmsTemplate jmsTemplate;

	@Autowired
	Sender(JmsTemplate jmsTemplate) {
		this.jmsTemplate = jmsTemplate;
	}

	// Converts the bookingId to String (TextMessage) to avoid JMS ObjectMessage serialization trust requirements.
	public void send(Object message) {
		jmsTemplate.convertAndSend("CheckINQ", String.valueOf(message));
	}
}
