package com.jasonyang.reminderbot;

import com.linecorp.bot.client.LineMessagingClient;
import com.linecorp.bot.model.event.Event;
import com.linecorp.bot.model.event.MessageEvent;
import com.linecorp.bot.model.event.message.TextMessageContent;
import com.linecorp.bot.model.message.TextMessage;
import com.linecorp.bot.spring.boot.annotation.EventMapping;
import com.linecorp.bot.spring.boot.annotation.LineMessageHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;

@Slf4j
@LineMessageHandler
public class MessageController {

  @Autowired
  private LineMessagingClient lineMessagingClient;

  @EventMapping
  public TextMessage handleTextMessage(MessageEvent<TextMessageContent> event) {
    log.info(event.toString());
    return new TextMessage("你說了:" + event.getMessage().getText());
  }

  @EventMapping
  public void handleDefaultMessageEvent(Event event) {
    System.out.println("event: " + event);
  }

}
