package com.agmadnasfelguc.walgreensreplica.user.service.command.helpers;

import com.agmadnasfelguc.walgreensreplica.user.model.User;
import com.agmadnasfelguc.walgreensreplica.user.repository.UserRepository;
import com.agmadnasfelguc.walgreensreplica.user.service.command.Command;
import com.agmadnasfelguc.walgreensreplica.user.service.response.ResponseState;
import com.agmadnasfelguc.walgreensreplica.user.service.response.ResponseStatus;
import lombok.Data;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Data
@Service
public class FindUserByEmailCommand extends Command {

    private String email;

    private User user;

    @Autowired
    private UserRepository userRepository;

    Logger logger = LoggerFactory.getLogger(FindUserByEmailCommand.class);

    @Override
    public void execute() {
        try {
            Optional<User> userOptional = userRepository.findByEmail(email);
            if (userOptional.isPresent()) {
                this.user = userOptional.get();
                this.setState(new ResponseStatus(ResponseState.Success, "User found"));
                logger.info("User found" + this.user.toString());
            } else {
                this.setState(new ResponseStatus(ResponseState.Failure, "User not found"));
                logger.error("User not found" + this.user.toString());
            }

        } catch (Exception e) {
            this.setState(new ResponseStatus(ResponseState.Failure, e.getMessage()));
            logger.error(e.getMessage());
        }
    }
}
