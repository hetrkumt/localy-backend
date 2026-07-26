package com.localy.payment_service.order.consumer;

import com.localy.payment_service.order.consumer.dto.OrderApprovedEvent;
import com.localy.payment_service.payment.service.PaymentProcessorService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.DltHandler;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.retry.annotation.Backoff;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class OrderApprovedEventListener {

    private final PaymentProcessorService paymentProcessorService;

    // 1. ?ъ떆??諛?DLQ(Dead Letter Queue) ?쇱슦???ㅼ젙
    // ?먮윭 諛쒖깮 ??理쒕? 3踰덇퉴吏 ?ъ떆?꾪븯硫? 媛꾧꺽? 1珥덈???2諛곗뵫 ?섏뼱??(1珥? 2珥? 4珥?
    @RetryableTopic(
            attempts = "3",
            backoff = @Backoff(delay = 1000, multiplier = 2.0),
            autoCreateTopics = "false"
    )
    @KafkaListener(topics = "order-approved", groupId = "payment-approved-group-e2e4b")
    public void handleOrderApprovedEvent(OrderApprovedEvent event) {
        log.info("PaymentService: OrderApprovedEvent 硫붿떆吏 ?섏떊! Order ID: {}, Amount: {}", event.getOrderId(), event.getTotalAmount());
        
        // Poison Pill ?쒕??덉씠?? 二쇰Ц 湲덉븸??0 ?댄븯??鍮꾩젙???곗씠?곕뒗 ?덉쇅 諛쒖깮
        if (event.getTotalAmount() == null || event.getTotalAmount().doubleValue() <= 0) {
            throw new IllegalArgumentException("Poison Pill Detected: 寃곗젣 湲덉븸??0 ?댄븯?낅땲?? (鍮꾩젙???곗씠??");
        }
        
        // 寃곗젣 泥섎━ ?쒕퉬???몄텧
        paymentProcessorService.processOrderApprovedEvent(event);
        log.info("PaymentService: 寃곗젣 泥섎━ ?꾨즺. Order ID: {}", event.getOrderId());
    }

    // 2. 3踰덉쓽 ?ъ떆?꾨쭏? 紐⑤몢 ?ㅽ뙣?섎㈃ 理쒖쥌?곸쑝濡???硫붿꽌???곕젅湲고넻)濡?寃⑸━??    @DltHandler
    public void handleDlt(OrderApprovedEvent event, @Header(KafkaHeaders.RECEIVED_TOPIC) String topic) {
        log.error("?슚 [DLQ 寃⑸━ ?꾨즺] 3???ъ떆???ㅽ뙣! 蹂듦뎄 遺덇??ν븳 硫붿떆吏瑜??곕젅湲고넻(DLQ)?쇰줈 蹂대깉?듬땲??");
        log.error(" - 寃⑸━??Order ID: {}", event.getOrderId());
        log.error(" - ?먮옒 ?좏뵿: {}", topic);
        // ?ν썑 ?댁쁺?먭? ?섎룞?쇰줈 蹂듦뎄?????덈룄濡??뚮┝(Slack ????蹂대궡嫄곕굹 DB???곸옱?섎뒗 濡쒖쭅 異붽?
    }
}
