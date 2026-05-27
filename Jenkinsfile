pipeline {
    agent any

    environment {
        IMAGE      = 'osolgil/siren-api'
        // EC2에 .env 파일을 이 경로에 배치해야 함
        DEPLOY_ENV = '/home/ubuntu/siren/.env'
    }

    stages {
        stage('Test') {
            steps {
                sh '''
                    docker run --rm \
                      -v "${WORKSPACE}/api:/workspace" \
                      -w /workspace \
                      python:3.11-slim \
                      sh -c "pip install -r requirements.txt -q && \
                             pytest tests/test_health.py tests/test_import_boundaries.py \
                               -v --tb=short"
                '''
            }
        }

        stage('Build') {
            steps {
                sh """
                    docker build \
                      -t ${IMAGE}:${BUILD_NUMBER} \
                      -t ${IMAGE}:latest \
                      ./api
                """
            }
        }

        stage('Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'HUB_USER',
                    passwordVariable: 'HUB_PASS'
                )]) {
                    sh """
                        echo "\$HUB_PASS" | docker login -u "\$HUB_USER" --password-stdin
                        docker push ${IMAGE}:${BUILD_NUMBER}
                        docker push ${IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy') {
            steps {
                // Jenkins가 EC2와 동일 서버이므로 SSH 불필요
                // workspace의 docker-compose.yml + EC2의 .env 조합으로 배포
                sh """
                    docker compose \
                      --env-file ${DEPLOY_ENV} \
                      -f "\${WORKSPACE}/docker-compose.yml" \
                      pull api

                    docker compose \
                      --env-file ${DEPLOY_ENV} \
                      -f "\${WORKSPACE}/docker-compose.yml" \
                      up -d api
                """
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
            // 오래된 이미지 정리 (dangling only — 실행 중 이미지 보호)
            sh 'docker image prune -f || true'
        }
        success {
            echo "Build #${BUILD_NUMBER} → ${IMAGE}:${BUILD_NUMBER} 배포 완료"
        }
        failure {
            echo "Build #${BUILD_NUMBER} 실패 — 위 로그를 확인하세요"
        }
    }
}
