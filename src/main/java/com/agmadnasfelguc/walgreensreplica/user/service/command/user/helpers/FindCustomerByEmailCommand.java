package com.agmadnasfelguc.walgreensreplica.user.service.command.user.helpers;

import com.agmadnasfelguc.walgreensreplica.user.model.Customer;
import com.agmadnasfelguc.walgreensreplica.user.model.User;
import com.agmadnasfelguc.walgreensreplica.user.repository.CustomerRepository;
import com.agmadnasfelguc.walgreensreplica.user.repository.UserRepository;
import com.agmadnasfelguc.walgreensreplica.user.service.command.Command;
import com.agmadnasfelguc.walgreensreplica.user.service.response.ResponseState;
import com.agmadnasfelguc.walgreensreplica.user.service.response.ResponseStatus;
import lombok.Data;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

@Data
@Service
public class FindCustomerByEmailCommand extends Command {
    private String email;

    private Customer customer;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private Command findUserByEmailCommand;

    public void execute() {
        try {
            ((FindUserByEmailCommand) findUserByEmailCommand).setEmail(email);
            findUserByEmailCommand.execute();
            if (findUserByEmailCommand.getState().getStatus().equals(ResponseState.Failure)) {
                this.setState(new ResponseStatus(ResponseState.Failure, "User not found"));
                return;
            }
            User user = ((FindUserByEmailCommand) findUserByEmailCommand).getUser();

            Optional<Customer> optCustomer = customerRepository.findById(UUID.fromString(user.getId()));
            if (optCustomer.isPresent()) {
                this.customer = optCustomer.get();
                this.setState(new ResponseStatus(ResponseState.Success, "Customer found"));
            } else {
                this.setState(new ResponseStatus(ResponseState.Failure, "Customer not found"));
            }

        } catch (Exception e) {
            this.setState(new ResponseStatus(ResponseState.Failure, e.getMessage()));
        }
    }
}
