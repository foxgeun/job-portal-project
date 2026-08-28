package com.jobportal.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jobportal.entity.JobPosting;
import com.jobportal.repository.JobPostingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class SaraminApiService {

    private final JobPostingRepository jobPostingRepository;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${saramin.api.key}")
    private String apiKey;

    @Value("${saramin.api.base-url}")
    private String baseUrl;

    @Value("${saramin.api.job-count:100}")
    private int jobCount;

    /**
     * 사람인 API를 호출하여 채용공고를 가져와 DB에 저장합니다.
     */
    @Transactional
    public int fetchAndSaveJobs() {
        return fetchAndSaveJobs("", "", jobCount);
    }

    @Transactional
    public int fetchAndSaveJobs(String keyword, String location, int count) {
        log.info("사람인 API 호출 시작 - keyword: {}, location: {}, count: {}", keyword, location, count);

        String url = UriComponentsBuilder.fromHttpUrl(baseUrl + "/job-search")
                .queryParam("access-key", apiKey)
                .queryParam("count", count)
                .queryParam("keywords", keyword)
                .queryParam("loc_mcd", location)
                .queryParam("fields", "posting-date,expiration-date,job-type,salary,experience-level,close-type")
                .build()
                .encode()
                .toUriString();

        int savedCount = 0;
        try {
            String response = restTemplate.getForObject(url, String.class);
            List<JobPosting> postings = parseApiResponse(response);

            if (!postings.isEmpty()) {
                List<String> urls = postings.stream().map(JobPosting::getJobUrl).toList();
                Set<String> existingUrls = jobPostingRepository.findAllByJobUrlIn(urls).stream()
                        .map(JobPosting::getJobUrl)
                        .collect(Collectors.toSet());

                List<JobPosting> newPostings = postings.stream()
                        .filter(p -> !existingUrls.contains(p.getJobUrl()))
                        .toList();

                if (!newPostings.isEmpty()) {
                    jobPostingRepository.saveAll(newPostings);
                    savedCount = newPostings.size();
                }
            }

            log.info("사람인 API 완료 - 신규 저장: {}건 / 전체 응답: {}건", savedCount, postings.size());
        } catch (Exception e) {
            log.error("사람인 API 호출 중 오류 발생: {}", e.getMessage(), e);
        }

        return savedCount;
    }

    private List<JobPosting> parseApiResponse(String jsonResponse) {
        List<JobPosting> postings = new ArrayList<>();
        try {
            JsonNode root = objectMapper.readTree(jsonResponse);
            JsonNode jobs = root.path("jobs").path("job");

            if (jobs.isArray()) {
                for (JsonNode job : jobs) {
                    try {
                        String jobUrl = job.path("url").asText();
                        if (jobUrl == null || jobUrl.isBlank()) continue;

                        JobPosting posting = JobPosting.builder()
                                .title(job.path("position").path("title").asText())
                                .companyName(job.path("company").path("detail").path("name").asText())
                                .location(job.path("position").path("location").path("name").asText())
                                .salary(job.path("salary").path("name").asText())
                                .jobUrl(jobUrl)
                                .jobType(job.path("position").path("job-type").path("name").asText())
                                .requiredExperience(job.path("position").path("experience-level").path("name").asText())
                                .postedDate(parseDate(job.path("posting-date").asText()))
                                .expirationDate(parseDate(job.path("expiration-date").asText()))
                                .build();
                        postings.add(posting);
                    } catch (Exception e) {
                        log.warn("공고 파싱 실패: {}", e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            log.error("API 응답 파싱 실패: {}", e.getMessage(), e);
        }
        return postings;
    }

    private LocalDate parseDate(String dateStr) {
        if (dateStr == null || dateStr.isBlank()) return null;
        try {
            // 1. ISO-8601 문자열 시도 (yyyy-MM-dd...)
            if (dateStr.length() >= 10 && dateStr.contains("-")) {
                return LocalDate.parse(dateStr.substring(0, 10), DateTimeFormatter.ISO_LOCAL_DATE);
            }
            // 2. UNIX timestamp 시도
            long timestamp = Long.parseLong(dateStr);
            return Instant.ofEpochSecond(timestamp).atZone(ZoneId.of("Asia/Seoul")).toLocalDate();
        } catch (Exception e) {
            return null;
        }
    }
}
