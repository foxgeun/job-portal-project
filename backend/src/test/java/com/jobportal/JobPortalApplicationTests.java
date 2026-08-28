package com.jobportal;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class JobPortalApplicationTests {

    @Test
    void contextLoads() {
        // Spring ApplicationContext가 정상적으로 로드되는지 확인
    }
}
