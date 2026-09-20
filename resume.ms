.\" resume.ms template — document chrome for the resume pipeline.
.\" Variables come from YAML front matter (name, title, location, email,
.\" phone, github, linkedin, margin-top/left/right/bottom).
\# Import TMAC template
.so resume.tmac
\# Setup Helvetica font
.fam H
.
\# Margin. Create a right margin of 0.5i by subtracting the left margin
\# plus 0.5i from the width of the entire page.
.nr PO 0.5i
.nr HM 0.6i
.nr FM 0.1i

.nr LL 21c
.nr LL -\n[PO]
.nr LL -0.5i
.nr LT \n[LL]
.
\# Main document starts here
.title Test Candidate
.subtitle Senior Software Engineer
.sp -4
.DS R
.nf
Springfield
test.candidate\(atexample.com
+15551234567
github.com/testcandidate
linkedin.com/in/testcandidate
.DE
.
\# change to left align mode
.ps 11
.vs 12
.PP
Software Engineer with 8 years of experience building \f[B]web, cloud, and AI\f[R] products. Specialized in \f[B]React and Node.js\f[R]. Led teams of up to 5 engineers and shipped systems used by millions of users. Open-source contributor and author of programming tutorials.
.section WORK EXPERIENCE
.item "Example Corp" "Tech Lead \- Springfield" "2021 - Present"
.list Lead a team of 5 engineers building a \f[B]SaaS analytics\f[R] platform.
.list Architected services handling millions of daily events.
.list Cut infrastructure costs by a third with a migration to containers.
.item "Acme Inc" "Software Engineer \- Springfield" "2018 - 2021"
.list Built \f[B]React\f[R] front ends backed by Node.js APIs.
.list Shipped features to millions of users across web and mobile.
.list Wrote integration tests covering the critical user flows.
.item "Foo Labs" "Software Engineer \- Springfield" "2016 - 2018"
.list Maintained internal tools and dashboards.
.list Automated releases, cutting deploy time in half.
.section EDUCATION
.item "Springfield University" "Springfield" "2012 - 2016"
.list B.Sc. Computer Science.
.section SKILLS
.item "Front End" "\&" "\&"
.LP
.ps 11
.vs 15
\f[B]TypeScript, React\f[R], Redux, Tailwind CSS, HTML, CSS, Vite, Jest, Playwright, React Native.
.item "Back End, AI, & Infrastructure" "\&" "\&"
.LP
.ps 11
.vs 15
\f[B]Node.js, Python\f[R], Express.js, FastAPI, SQL, PostgreSQL, Redis, AWS, Docker, RESTful APIs, GraphQL.
.item "Other Skills" "\&" "\&"
.LP
.ps 11
.vs 15
English (Native), Mentorship, Technical Writing.
