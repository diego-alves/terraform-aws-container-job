output repository_url {
    value = aws_ecr_repository.ecr.repository_url
    description = "The docker repository for the image which will run the job"
}