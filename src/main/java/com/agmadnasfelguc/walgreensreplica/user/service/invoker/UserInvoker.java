package com.agmadnasfelguc.walgreensreplica.user.service.invoker;

import com.agmadnasfelguc.walgreensreplica.user.service.command.Command;
import com.agmadnasfelguc.walgreensreplica.user.service.kafka.message.creator.MessageCreator;
import com.agmadnasfelguc.walgreensreplica.user.service.kafka.message.creator.TemplatePaths;
import com.agmadnasfelguc.walgreensreplica.user.service.kafka.message.keys.Keys;
import com.agmadnasfelguc.walgreensreplica.user.service.kafka.message.processor.Processor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;

import java.util.HashMap;
import java.util.Map;

@Service
public class UserInvoker {
    private final CommandToReqMapper map;

    @Autowired
    private ApplicationContext applicationContext;

    public UserInvoker() {
        this.map = CommandToReqMapper.getInstance();
    }

    public void callCommand(JsonNode body){
        String request = body.get("request").asText();
        System.out.println("Request: " + request);
        String commandName = map.getCommandsMap().get(request);
        if(commandName == null){
            System.out.println("Command not found");
            return;
        }
        try {
//            Class<?> commandClass = applicationContext.getBean(commandName);
            Class<?> processorClass = Class.forName("com.agmadnasfelguc.walgreensreplica.user.service.kafka.message.processor." + request + "Processor");
            Processor processor = (Processor) processorClass.getDeclaredConstructor().newInstance();
            Command command = (Command) applicationContext.getBean(commandName);
            processor.init(command,body);
            processor.process();
            command.execute();
            System.out.println(command.getState());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

//    public static void main(String[] args) {
//        UserInvoker userInvoker = new UserInvoker();
//        Map<String,String> bodyMap = new HashMap<>();
//        bodyMap.put(Keys.email,"omarmmi2000@gmail.com");
//        bodyMap.put(Keys.password,"changed");
//        MessageCreator creator = new MessageCreator(TemplatePaths.userLoginPath,new HashMap<>(),bodyMap);
//        JsonNode jsonNode = creator.createMessage();
//        userInvoker.callCommand(jsonNode);
//    }

}
