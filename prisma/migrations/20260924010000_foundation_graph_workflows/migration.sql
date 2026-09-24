-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT,
    "username" TEXT NOT NULL,
    "password" TEXT,
    "credits" INTEGER NOT NULL DEFAULT 0,
    "isGuest" BOOLEAN NOT NULL DEFAULT false,
    "emailVerified" BOOLEAN NOT NULL DEFAULT false,
    "isAdmin" BOOLEAN NOT NULL DEFAULT false,
    "followBonusClaimed" BOOLEAN NOT NULL DEFAULT false,
    "twitterId" TEXT,
    "twitterUsername" TEXT,
    "twitterAccessToken" TEXT,
    "twitterRefreshToken" TEXT,
    "twitterTokenExpiry" TIMESTAMP(3),
    "sessionCookie" TEXT,
    "authMethod" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Subscription" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "tier" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "stripeCustomerId" TEXT,
    "stripeSubscriptionId" TEXT,
    "stripePriceId" TEXT,
    "startDate" TIMESTAMP(3) NOT NULL,
    "endDate" TIMESTAMP(3),
    "cancelAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Subscription_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Operation" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "config" TEXT,
    "result" TEXT,
    "unfollowedCount" INTEGER DEFAULT 0,
    "followedCount" INTEGER DEFAULT 0,
    "creditsUsed" INTEGER NOT NULL DEFAULT 0,
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "error" TEXT,
    "retryCount" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Operation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Payment" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'usd',
    "stripePaymentId" TEXT,
    "stripeInvoiceId" TEXT,
    "status" TEXT NOT NULL,
    "creditsAdded" INTEGER,
    "metadata" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "JobQueue" (
    "id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "data" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "priority" INTEGER NOT NULL DEFAULT 0,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "maxAttempts" INTEGER NOT NULL DEFAULT 3,
    "processedAt" TIMESTAMP(3),
    "failedAt" TIMESTAMP(3),
    "error" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "JobQueue_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CryptoPayment" (
    "id" TEXT NOT NULL,
    "paymentId" TEXT NOT NULL,
    "userId" TEXT,
    "email" TEXT,
    "package" TEXT NOT NULL,
    "credits" INTEGER NOT NULL,
    "amountUSD" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "txHash" TEXT,
    "provider" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "confirmedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CryptoPayment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "License" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "tier" TEXT NOT NULL,
    "customerName" TEXT,
    "customerEmail" TEXT,
    "companyName" TEXT,
    "maxUsers" INTEGER NOT NULL DEFAULT 500,
    "maxInstances" INTEGER NOT NULL DEFAULT 1,
    "whiteLabel" BOOLEAN NOT NULL DEFAULT false,
    "customDomain" BOOLEAN NOT NULL DEFAULT false,
    "apiAccess" BOOLEAN NOT NULL DEFAULT false,
    "activations" INTEGER NOT NULL DEFAULT 0,
    "lastActivatedAt" TIMESTAMP(3),
    "instanceIds" TEXT,
    "status" TEXT NOT NULL DEFAULT 'active',
    "expiresAt" TIMESTAMP(3),
    "paymentId" TEXT,
    "amountPaid" DOUBLE PRECISION,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "License_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AccountSnapshot" (
    "id" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'full',
    "data" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AccountSnapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FollowerSnapshot" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "followers" TEXT NOT NULL,
    "totalCount" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FollowerSnapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FollowerChange" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "name" TEXT,
    "avatarUrl" TEXT,
    "detectedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "followedSince" TIMESTAMP(3),

    CONSTRAINT "FollowerChange_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UnfollowerSchedule" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "interval" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "lastRunAt" TIMESTAMP(3),
    "nextRunAt" TIMESTAMP(3),
    "webhookUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UnfollowerSchedule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SocialGraph" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "sourceUsername" TEXT,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "filters" TEXT,
    "influenceModel" TEXT NOT NULL DEFAULT 'pagerank',
    "nodeCount" INTEGER NOT NULL DEFAULT 0,
    "edgeCount" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SocialGraph_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SocialGraphNode" (
    "id" TEXT NOT NULL,
    "graphId" TEXT NOT NULL,
    "externalId" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "displayName" TEXT,
    "avatarUrl" TEXT,
    "clusterId" TEXT,
    "influence" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "followers" INTEGER NOT NULL DEFAULT 0,
    "following" INTEGER NOT NULL DEFAULT 0,
    "metadata" TEXT,

    CONSTRAINT "SocialGraphNode_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SocialGraphEdge" (
    "id" TEXT NOT NULL,
    "graphId" TEXT NOT NULL,
    "sourceId" TEXT NOT NULL,
    "targetId" TEXT NOT NULL,
    "relation" TEXT NOT NULL DEFAULT 'follows',
    "weight" DOUBLE PRECISION NOT NULL DEFAULT 1,
    "metadata" TEXT,

    CONSTRAINT "SocialGraphEdge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Workflow" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "trigger" TEXT NOT NULL,
    "definition" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Workflow_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorkflowRun" (
    "id" TEXT NOT NULL,
    "workflowId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'queued',
    "trigger" TEXT NOT NULL,
    "input" TEXT,
    "output" TEXT,
    "error" TEXT,
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WorkflowRun_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RealtimeEvent" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "workflowRunId" TEXT,
    "topic" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "payload" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RealtimeEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");

-- CreateIndex
CREATE UNIQUE INDEX "User_twitterId_key" ON "User"("twitterId");

-- CreateIndex
CREATE INDEX "User_email_idx" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_username_idx" ON "User"("username");

-- CreateIndex
CREATE UNIQUE INDEX "Subscription_userId_key" ON "Subscription"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Subscription_stripeCustomerId_key" ON "Subscription"("stripeCustomerId");

-- CreateIndex
CREATE UNIQUE INDEX "Subscription_stripeSubscriptionId_key" ON "Subscription"("stripeSubscriptionId");

-- CreateIndex
CREATE INDEX "Subscription_userId_idx" ON "Subscription"("userId");

-- CreateIndex
CREATE INDEX "Subscription_stripeCustomerId_idx" ON "Subscription"("stripeCustomerId");

-- CreateIndex
CREATE INDEX "Operation_userId_status_idx" ON "Operation"("userId", "status");

-- CreateIndex
CREATE INDEX "Operation_createdAt_idx" ON "Operation"("createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_stripePaymentId_key" ON "Payment"("stripePaymentId");

-- CreateIndex
CREATE INDEX "Payment_userId_idx" ON "Payment"("userId");

-- CreateIndex
CREATE INDEX "Payment_createdAt_idx" ON "Payment"("createdAt");

-- CreateIndex
CREATE INDEX "JobQueue_status_priority_idx" ON "JobQueue"("status", "priority");

-- CreateIndex
CREATE INDEX "JobQueue_createdAt_idx" ON "JobQueue"("createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "CryptoPayment_paymentId_key" ON "CryptoPayment"("paymentId");

-- CreateIndex
CREATE INDEX "CryptoPayment_paymentId_idx" ON "CryptoPayment"("paymentId");

-- CreateIndex
CREATE INDEX "CryptoPayment_userId_idx" ON "CryptoPayment"("userId");

-- CreateIndex
CREATE INDEX "CryptoPayment_status_idx" ON "CryptoPayment"("status");

-- CreateIndex
CREATE INDEX "CryptoPayment_email_idx" ON "CryptoPayment"("email");

-- CreateIndex
CREATE UNIQUE INDEX "License_key_key" ON "License"("key");

-- CreateIndex
CREATE INDEX "License_key_idx" ON "License"("key");

-- CreateIndex
CREATE INDEX "License_customerEmail_idx" ON "License"("customerEmail");

-- CreateIndex
CREATE INDEX "License_status_idx" ON "License"("status");

-- CreateIndex
CREATE INDEX "AccountSnapshot_username_type_idx" ON "AccountSnapshot"("username", "type");

-- CreateIndex
CREATE INDEX "AccountSnapshot_createdAt_idx" ON "AccountSnapshot"("createdAt");

-- CreateIndex
CREATE INDEX "FollowerSnapshot_userId_idx" ON "FollowerSnapshot"("userId");

-- CreateIndex
CREATE INDEX "FollowerSnapshot_username_createdAt_idx" ON "FollowerSnapshot"("username", "createdAt");

-- CreateIndex
CREATE INDEX "FollowerChange_userId_detectedAt_idx" ON "FollowerChange"("userId", "detectedAt");

-- CreateIndex
CREATE INDEX "FollowerChange_userId_type_idx" ON "FollowerChange"("userId", "type");

-- CreateIndex
CREATE UNIQUE INDEX "UnfollowerSchedule_userId_key" ON "UnfollowerSchedule"("userId");

-- CreateIndex
CREATE INDEX "UnfollowerSchedule_active_nextRunAt_idx" ON "UnfollowerSchedule"("active", "nextRunAt");

-- CreateIndex
CREATE INDEX "SocialGraph_userId_updatedAt_idx" ON "SocialGraph"("userId", "updatedAt");

-- CreateIndex
CREATE INDEX "SocialGraph_userId_status_idx" ON "SocialGraph"("userId", "status");

-- CreateIndex
CREATE INDEX "SocialGraphNode_graphId_influence_idx" ON "SocialGraphNode"("graphId", "influence");

-- CreateIndex
CREATE INDEX "SocialGraphNode_graphId_clusterId_idx" ON "SocialGraphNode"("graphId", "clusterId");

-- CreateIndex
CREATE UNIQUE INDEX "SocialGraphNode_graphId_externalId_key" ON "SocialGraphNode"("graphId", "externalId");

-- CreateIndex
CREATE INDEX "SocialGraphEdge_graphId_sourceId_idx" ON "SocialGraphEdge"("graphId", "sourceId");

-- CreateIndex
CREATE INDEX "SocialGraphEdge_graphId_targetId_idx" ON "SocialGraphEdge"("graphId", "targetId");

-- CreateIndex
CREATE UNIQUE INDEX "SocialGraphEdge_graphId_sourceId_targetId_relation_key" ON "SocialGraphEdge"("graphId", "sourceId", "targetId", "relation");

-- CreateIndex
CREATE INDEX "Workflow_userId_updatedAt_idx" ON "Workflow"("userId", "updatedAt");

-- CreateIndex
CREATE INDEX "Workflow_userId_enabled_idx" ON "Workflow"("userId", "enabled");

-- CreateIndex
CREATE INDEX "WorkflowRun_workflowId_createdAt_idx" ON "WorkflowRun"("workflowId", "createdAt");

-- CreateIndex
CREATE INDEX "WorkflowRun_userId_status_createdAt_idx" ON "WorkflowRun"("userId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "RealtimeEvent_userId_createdAt_idx" ON "RealtimeEvent"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "RealtimeEvent_topic_createdAt_idx" ON "RealtimeEvent"("topic", "createdAt");

-- CreateIndex
CREATE INDEX "RealtimeEvent_workflowRunId_createdAt_idx" ON "RealtimeEvent"("workflowRunId", "createdAt");

-- AddForeignKey
ALTER TABLE "Subscription" ADD CONSTRAINT "Subscription_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Operation" ADD CONSTRAINT "Operation_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CryptoPayment" ADD CONSTRAINT "CryptoPayment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SocialGraph" ADD CONSTRAINT "SocialGraph_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SocialGraphNode" ADD CONSTRAINT "SocialGraphNode_graphId_fkey" FOREIGN KEY ("graphId") REFERENCES "SocialGraph"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SocialGraphEdge" ADD CONSTRAINT "SocialGraphEdge_graphId_fkey" FOREIGN KEY ("graphId") REFERENCES "SocialGraph"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Workflow" ADD CONSTRAINT "Workflow_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkflowRun" ADD CONSTRAINT "WorkflowRun_workflowId_fkey" FOREIGN KEY ("workflowId") REFERENCES "Workflow"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkflowRun" ADD CONSTRAINT "WorkflowRun_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RealtimeEvent" ADD CONSTRAINT "RealtimeEvent_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RealtimeEvent" ADD CONSTRAINT "RealtimeEvent_workflowRunId_fkey" FOREIGN KEY ("workflowRunId") REFERENCES "WorkflowRun"("id") ON DELETE CASCADE ON UPDATE CASCADE;

