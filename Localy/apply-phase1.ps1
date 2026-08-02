# DEPRECATED (Wave 5): Phase-1 string-injection of OTel/Prometheus/Graceful Shutdown.
# Observability config now lives in each service's application.yml / build.gradle (SSOT).
# Do not re-run this script — it appends duplicate blocks and drifts from GitOps.

Write-Error @"
apply-phase1.ps1 is retired (Wave 5 / Area 1-5 legacy cleanup).

Use:
  - Service source under Localy/<svc>/ (application.yml, build.gradle)
  - GitOps manifests under localy-manifests/workloads/
  - CI: .github/workflows/build-push-ecr.yml
"@
exit 1
