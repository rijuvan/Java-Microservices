package com.brownfield.pss.book.component;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

// ActiveMQ: JmsTemplate replaces RabbitMessagingTemplate.
// Queues (SearchQ, CheckINQ) are auto-created by the broker on first send — no @Bean Queue declarations needed.
@Component
public class Sender {

	JmsTemplate jmsTemplate;

	@Autowired
	Sender(JmsTemplate jmsTemplate) {
		this.jmsTemplate = jmsTemplate;
	}

	// Sends booking event to search service so it can update its flight inventory cache.
	// Payload is a Map<String,Object> — converted to JMS MapMessage by Spring's SimpleMessageConverter.
	public void send(Object message) {
		jmsTemplate.convertAndSend("SearchQ", message);
	}
}
