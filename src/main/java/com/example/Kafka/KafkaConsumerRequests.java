package com.example.Kafka;

import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import com.example.Commands.Invoker;
import com.example.Final.CartTable;
import com.fasterxml.jackson.databind.ObjectMapper;


@Service
public class KafkaConsumerRequests {
	@Autowired
	Invoker invoker=new Invoker();
	@Autowired
	KafkaProducer kafkaProducer;
	
	Logger logger = LoggerFactory.getLogger(KafkaConsumerRequests.class);
	@KafkaListener(topics="cartRequests",groupId = "KafkaGroupRequestCart")
	public void consumeMessage(String message) {
		try {
			logger.info("Request: "+message);
			
			message=message.replace("\\", "");
			message=message.substring(1, message.length()-1);
			ObjectMapper objectMapper = new ObjectMapper();
			@SuppressWarnings("unchecked")
			Map<String,Object> data = objectMapper.readValue(message, HashMap.class);
			Map<String,Object> result = new HashMap<>();
			result.put("commandName", data.get("commandName").toString());
			Object finalData="";
			String jsonString2="";
			switch (data.get("commandName").toString()) {
				
				case "UpdateItemCountCommandCache":
					finalData = (String) invoker.executeCommand("UpdateItemCountCommandCache", data);
					data.replace("commandName", "UpdateItemCountCommand");
					jsonString2=objectMapper.writeValueAsString(data);
					kafkaProducer.publishToTopic("cartRequests", jsonString2);
					break;

				case "UpdateItemCountCommand":
					finalData= (String) invoker.executeCommand("UpdateItemCountCommand", data);
					break;

				case "AddToSavedForLaterCache":
				finalData = (String) invoker.executeCommand("AddToSavedForLaterCache", data);
				data.replace("commandName", "AddToSavedForLater");
				jsonString2=objectMapper.writeValueAsString(data);
				kafkaProducer.publishToTopic("cartRequests", jsonString2);
				break;
				case "AddToSavedForLater":
					finalData= (String) invoker.executeCommand("AddToSavedForLater", data);
					break;

				case "ReturnFromSavedForLaterCache":
					finalData = (String) invoker.executeCommand("ReturnFromSavedForLaterCache", data);
					data.replace("commandName", "ReturnFromSavedForLater");
					jsonString2=objectMapper.writeValueAsString(data);
					kafkaProducer.publishToTopic("cartRequests", jsonString2);
					break;
				case "ReturnFromSavedForLater":
					finalData= (String) invoker.executeCommand("ReturnFromSavedForLater", data);
					break;
				case "GetUserCart":
					finalData = (Object) invoker.executeCommand("GetUserCart", data);
					break;
				case "RemoveItem":
					finalData = (Object) invoker.executeCommand("RemoveItem", data);
					break;
				case "ChangeOrderType":
					finalData = (Object) invoker.executeCommand("ChangeOrderType", data);
					break;
				case "ApplyPromo":
					finalData = (Object) invoker.executeCommand("ApplyPromo", data);
					break;
				case "AddItem":
					finalData = (Object) invoker.executeCommand("AddItem", data);
					break;
				case "AddComment":
					finalData = (Object) invoker.executeCommand("AddComment", data);
					break;
			
				case "ProceedToCheckOutCommand":
					finalData = (Object) invoker.executeCommand("ProceedToCheckOutCommand", data);
					break;
				case "ConfirmCheckoutCommand":
					finalData = (Object) invoker.executeCommand("ConfirmCheckoutCommand", data);
					break;
				case "GetProductForCartCommand":
					finalData = (Object) invoker.executeCommand("AddItem", data);
					break;
				default:
					break;
			}
			result.put("data", finalData);
			String response = objectMapper.writeValueAsString(result);
			kafkaProducer.publishToTopic("cartResponses", response);
			
		} catch (Exception e) {
			e.printStackTrace();
		}
		
	}

}
