terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
  backend "gcs" {
    bucket  = "kubernetes-study"
    prefix  = "terraform/state"
    GOOGLE_BACKEND_CREDENTIALS = {"type": "service_account","project_id": "kube-293902","private_key_id":"2f633e51bc7c962733c01c7046cefdff98620602","private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCTj/koe2YyvFJy\n2qMn4D4X1xgh4krH+hZsVA9+VKcmGvbInX28uK0zP1QYnmY+SyFSVPDLcaIYBzf0\ne3ChxAg85/TnupeW2Rtr0cMGlFIw4IkLghKIJiCtu6B63e0Aer/xwOoHnEAecKAF\nAAcGHY+pyL0fG+Cyl2MM0rf5/6GKdlRDDSTTBbxq9cHPT+fF0dKcP8EEH/QbWXn2\nL8MgBq7W6oNr7rNfV4Y87rS3c3WBIjNjXqdDZ1UX4qxxZeUb+cZengbMmNCibRdt\nY7sNEu1f9Dso/rF130MJdvDFB9X8CNLvSXZ1mVFYcapDKa0/jBaHzh8N7wfneNRz\nI3JAwcy5AgMBAAECggEABwWGTyFUExz39WQm+FpIyhyfltksQsjJMV1soU/I5lzJ\nGnG4DndhMnuUdllvNw6fJspI7P1av7b0OCt5iBEKbU+CTVaJKRHqpp5EH/eF07KT\ngtstI5Jg4rN3ZvFRekDdClVqLXOHb4tfae1+6BEXCXa2XRkX/5eJjI4oV/qMhsiZ\nJr8T2SCJ+o2XhDtS9pCdJEvFzNhrFUA3b76nlQmtW4k0n4u55cvTxPvuV0LcZFLv\n68sfbt1V6UbjH0gTeOMnhViKqKixEuFFOUoOa5ER7Bg6Nw5Q8oi3m0W3xt8VjFZH\n+pBxnqoDLejs9uLP86k7rcjiSUPOxf8jluujJY0/CwKBgQDJN5ATXdYZ8D/kVc5x\n579mE9TQwjoe7hYCJdeHCOB3xTl162nOn1z0UwTOCtjwAcvm7FIlTJcqaaqIsBDm\nM5iLGuPcxHD3Eg92+PA00+NecdobsJRaKF1fUuLpKjsrwpGy3CH6QVNDjHoJR/u2\n18u5ZwvSKt4XUw3jXUIqXHT2owKBgQC7vMkoly5QAvmql8TsSuB+7bmIUiJB5GIn\nksTlYwVYqvMp7QOv9rcA/3yxljehbyNh3y1oT9GKJJHVBC28S0ns3i0CPg99qE7X\niGrYtuiXfrvQ9+ZWvYw4rZALVR2ncJpwftKWlmb8MdVTQba9MLHDx+6AGXGOs92d\njaG8sQCQ8wKBgAE/HN9h12+1s0+g0HSYMPFa8hiQ+3cxlmVRArLNdUaIrEB0wuUK\ny7KfyQnVu15RRIgbsq6UeONEYFAUdyZV7339HqhBd0mwjPP5utM49NGi9uzw/RpJ\n4bozc0BqiI9O10Q6ZON+ABwNBLyF+6M4VwTBBKu6pEGUvCNKcpx8kiTtAoGAUoSK\nToMU4ipMnwUSk2HeByxqblbbo+bElexXCxRZFz4cn4MEKeXhTlj97/i8/wIgpTY5\neS4MRhII3350s9zL44dMdT3eBTdjYC0f+Z174orb9t/fqKSr64WuWKzS2fQOjf/Q\nhEwbfCJTR8MMlV+/4vQQCtIkLbs1X7kPLCcIvq0CgYEAnRgoLOPJaPWOJawp5P9w\nSPuSijUlzTkdaIA4uv8kTsvGxDTzZzdDRTI9K0h+ns2WkxYJlt4J37EBjjvBLmqP\nIprM6dX3D/3W91Fzzuc4hKadNk4PUgjHLZsCpLuel/eG0sC2yGORonMwq0cs2qpp\nskKhDkZo5s7expjn21svCyo=\n-----END PRIVATE KEY-----\n","client_email": "admin-terraform@kube-293902.iam.gserviceaccount.com","client_id": "109410131977717189012","auth_uri": "https://accounts.google.com/o/oauth2/auth","token_uri": "https://oauth2.googleapis.com/token","auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/admin-terraform%40kube-293902.iam.gserviceaccount.com"}
  }
}

provider "google" {
  version = "3.5.0"

//  credentials = file("Kube-terraform-2f633e51bc7c.json")

  project = var.PROJECT_ID
  region  = var.REGION
  zone    = var.ZONE
}




