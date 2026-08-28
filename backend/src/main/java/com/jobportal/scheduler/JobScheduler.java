package com.jobportal.scheduler;

import com.jobportal.service.JobPostingService;
import com.jobportal.service.SaraminApiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class JobScheduler {

    private final SaraminApiService saraminApiService;
    private final JobPostingService jobPostingService;

    /**
     * 매일 자정(00:00)에 실행:
     * 1. 사람인 API에서 최신 채용공고를 가져와 저장
     * 2. 만료된 채용공고를 삭제
     */
    @Scheduled(cron = "0 0 0 * * *", zone = "Asia/Seoul")
    public void scheduledJobFetch() {
        log.info("===== 채용공고 배치 스케줄러 시작 =====");

        // 1단계: 만료 공고 삭제
        try {
            int deleted = jobPostingService.deleteExpiredPostings();
            log.info("만료 공고 삭제 완료: {}건", deleted);
        } catch (Exception e) {
            log.error("만료 공고 삭제 중 오류: {}", e.getMessage(), e);
        }

        // 2단계: 사람인 API에서 신규 공고 수집
        try {
            int saved = saraminApiService.fetchAndSaveJobs();
            log.info("신규 공고 저장 완료: {}건", saved);
        } catch (Exception e) {
            log.error("채용공고 수집 중 오류: {}", e.getMessage(), e);
        }

        log.info("===== 채용공고 배치 스케줄러 종료 =====");
    }
}
