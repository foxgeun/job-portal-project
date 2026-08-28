package com.jobportal;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class JobPortalApplicationTests {

    @Test
    void contextLoads() {
        // Spring ApplicationContext가 정상적으로 로드되는지 확인
        // test 프로파일에서는 H2 인메모리 DB를 사용
    }
}
