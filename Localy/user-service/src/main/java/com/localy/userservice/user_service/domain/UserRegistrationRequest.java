package com.localy.userservice.user_service.domain;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class UserRegistrationRequest {

    @NotBlank(message = "사용자명은 필수입니다.")
    private String username;

    @NotBlank(message = "비밀번호는 필수입니다.")
    @Size(min = 8, message = "비밀번호는 최소 8자 이상이어야 합니다.")
    private String password;

    @NotBlank(message = "이메일은 필수입니다.")
    @Email(message = "유효한 이메일 형식이 아닙니다.")
    private String email;

    private String firstName; // 선택 사항
    private String lastName;  // 선택 사항

    // 기본 생성자, 모든 필드 생성자, getter, setter, toString 등은 Lombok이 자동 생성하거나 필요에 따라 추가
}