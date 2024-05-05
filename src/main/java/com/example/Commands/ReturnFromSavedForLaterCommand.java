package com.example.Commands;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.example.Final.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import io.jsonwebtoken.Claims;

@Service
public class ReturnFromSavedForLaterCommand implements Command {
    private JwtDecoderService jwtDecoderService;
    
    private CartRepo cartRepo;
    
    @Autowired
    public ReturnFromSavedForLaterCommand(CartRepo cartRepo, JwtDecoderService jwtDecoderService , PromoRepo promoRepo, UserUsedPromoRepo userUsedPromoRepo) {
    	this.cartRepo=cartRepo;
    	this.jwtDecoderService=jwtDecoderService;
    }

    @Override
    public Object execute(Map<String, Object> data) {
        String itemId=(String)data.get("itemId");
        String token =(String)data.get("token");
        String secretKey = "ziad1234aaaa&&&&&thisisasecretekeyaaa"; 
	    Claims claims = jwtDecoderService.decodeJwtToken(token, secretKey);
        if (claims != null) {
            // Extract claims from the JWT token and perform necessary actions
            String userId=(String) claims.get("userId");
            CartTable oldCart=cartRepo.getCart(UUID.fromString(userId));
            List<CartItem> oldItems=oldCart.getItems();
            List<CartItem> newSaved=oldCart.getSavedForLaterItems();
            UUID cartId=oldCart.getId();
            boolean found=false;
            double newTotal=0;
            if(oldItems==null) {
            	oldItems=new ArrayList<CartItem>();
            }
            for(int i=0;i<newSaved.size();i++) {
            	if(newSaved.get(i).getItemId().equals(UUID.fromString(itemId))) {
            		oldItems.add(newSaved.get(i));
            		int oldcount=newSaved.get(i).getItemCount();
        			double increase=(oldcount)*newSaved.get(i).getPurchasedPrice();
        			if(oldCart.getAppliedPromoCodeId() !=null) {
        				increase=increase - increase*oldCart.getPromoCodeAmount()/100.0;
        			}
        			newTotal=oldCart.getTotalAmount()+increase;
            		newSaved.remove(i);
            		found=true;
            	}
            }
            if(found)
            	cartRepo.updateCartItemsAndSaved(oldItems,newSaved, cartId,newTotal);
            else {
            	return "invalid item id";
            }
            
            return "success";
            
        } else {
            return "failed";
        }

    }

}
