package com.jobportal.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "job_postings")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JobPosting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 500)
    private String title;

    @Column(nullable = false, length = 200)
    private String companyName;

    @Column(length = 200)
    private String location;

    @Column(length = 100)
    private String salary;

    @Column(unique = true, nullable = false, length = 1000)
    private String jobUrl;

    private LocalDate postedDate;

    private LocalDate expirationDate;

    @Column(length = 100)
    private String jobType;

    @Column(length = 100)
    private String requiredExperience;

    @Column(length = 2000)
    private String description;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
