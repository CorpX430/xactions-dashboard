-- Add the external Clerk identity mapping without changing existing local users.
ALTER TABLE "User" ADD COLUMN "clerkId" TEXT;
CREATE UNIQUE INDEX "User_clerkId_key" ON "User"("clerkId");
