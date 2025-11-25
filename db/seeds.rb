puts "Seeding database..."

User.destroy_all
Project.destroy_all

admin = User.create!(
  email: 'admin@ninesmanager.com',
  password: 'password123',
  name: 'Admin User',
  role: 'admin'
)

editor = User.create!(
  email: 'editor@ninesmanager.com',
  password: 'password123',
  name: 'Editor User',
  role: 'editor'
)

viewer = User.create!(
  email: 'viewer@ninesmanager.com',
  password: 'password123',
  name: 'Viewer User',
  role: 'viewer'
)

puts "Created #{User.count} users"

project1 = admin.owned_projects.create!(
  name: 'Website Redesign',
  description: 'Complete overhaul of the company website with modern design and improved UX'
)

project2 = admin.owned_projects.create!(
  name: 'Mobile App Development',
  description: 'Build native mobile applications for iOS and Android platforms'
)

project3 = editor.owned_projects.create!(
  name: 'Marketing Campaign Q1',
  description: 'Launch new marketing campaign for Q1 2024 across all channels'
)

puts "Created #{Project.count} projects"

project1.project_members.create!(user: editor, role: 'editor')
project1.project_members.create!(user: viewer, role: 'viewer')

board1 = project1.boards.first
column1 = board1.columns.find_by(name: 'To Do')
column2 = board1.columns.find_by(name: 'In Progress')
column3 = board1.columns.find_by(name: 'Done')

tasks_data = [
  { title: 'Design homepage mockup', description: 'Create initial design concepts for the new homepage', priority: 'high', column: column1 },
  { title: 'Set up development environment', description: 'Configure local dev environment with all necessary tools', priority: 'high', column: column3 },
  { title: 'Research competitor websites', description: 'Analyze top 10 competitor websites for inspiration', priority: 'medium', column: column3 },
  { title: 'Implement navigation menu', description: 'Build responsive navigation menu component', priority: 'urgent', column: column2 },
  { title: 'Create user authentication flow', description: 'Implement login, signup, and password reset', priority: 'high', column: column2 },
  { title: 'Write documentation', description: 'Document all components and APIs', priority: 'low', column: column1 },
  { title: 'Performance optimization', description: 'Optimize page load times and bundle size', priority: 'medium', column: column1 },
  { title: 'Browser compatibility testing', description: 'Test across Chrome, Firefox, Safari, and Edge', priority: 'medium', column: column1 }
]

tasks_data.each do |task_data|
  project1.tasks.create!(
    title: task_data[:title],
    description: task_data[:description],
    priority: task_data[:priority],
    column: task_data[:column],
    user: [admin, editor].sample,
    due_date: rand(1..30).days.from_now
  )
end

project2.tasks.create!([
  { title: 'Define app requirements', description: 'Gather and document all requirements', priority: 'urgent', user: admin },
  { title: 'UI/UX design', description: 'Create wireframes and mockups', priority: 'high', user: editor },
  { title: 'Set up CI/CD pipeline', description: 'Configure automated build and deployment', priority: 'medium', user: admin }
])

project3.tasks.create!([
  { title: 'Social media strategy', description: 'Plan content calendar for Q1', priority: 'high', user: editor },
  { title: 'Email campaign templates', description: 'Design email templates', priority: 'medium', user: editor }
])

puts "Created #{Task.count} tasks"

project1.documents.create!([
  {
    title: 'Project Requirements',
    content: "# Website Redesign Requirements\n\n## Overview\nComplete redesign of the company website.\n\n## Goals\n- Improve user experience\n- Modernize design\n- Increase conversion rates\n\n## Timeline\n3 months from kickoff",
    user: admin
  },
  {
    title: 'Design Guidelines',
    content: "# Design Guidelines\n\n## Colors\n- Primary: #4F46E5\n- Secondary: #10B981\n- Neutral: #6B7280\n\n## Typography\n- Headings: Inter Bold\n- Body: Inter Regular",
    user: editor
  }
])

project2.documents.create!(
  title: 'Technical Specifications',
  content: "# Mobile App Technical Specs\n\n## Platform\n- iOS 14+\n- Android 10+\n\n## Tech Stack\n- React Native\n- Redux for state management\n- Firebase for backend",
  user: admin
)

project3.documents.create!(
  title: 'Campaign Brief',
  content: "# Q1 Marketing Campaign\n\n## Target Audience\n- Age: 25-45\n- Interests: Technology, Innovation\n\n## Channels\n- Social Media\n- Email\n- Content Marketing",
  user: editor
)

puts "Created #{Document.count} documents"
puts "Seeding complete!"
puts "\nTest Users:"
puts "Admin: admin@ninesmanager.com / password123"
puts "Editor: editor@ninesmanager.com / password123"
puts "Viewer: viewer@ninesmanager.com / password123"
