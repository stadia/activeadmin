# frozen_string_literal: true
Then /^I should see the attribute "([^"]*)" with "([^"]*)"$/ do |title, value|
  elems = all ".attributes-table th:contains('#{title}') ~ td:contains('#{value}')"
  expect(elems.first).to_not eq(nil), "attribute missing"
end

Then /^I should see the attribute "([^"]*)" with a nicely formatted datetime$/ do |title|
  text = all(".attributes-table th:contains('#{title}') ~ td").first.text
  expect(text).to match /\w+ \d{1,2}, \d{4} \d{2}:\d{2}/
end

Then /^I should not see the attribute "([^"]*)"$/ do |title|
  expect(page).to have_no_css ".attributes-table th", text: title
end
