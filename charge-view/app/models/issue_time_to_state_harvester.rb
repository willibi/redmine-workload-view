class IssueTimeToStateHarvester < DataHarvester
  
  def initialize (state_name, issues)
    @state_name = state_name
    super(issues)
  end
  
  def compute(issue)
    wc = WorkDayComparator.new
    results = []
    journal = Journal.find_by_sql(
    [ "SELECT *
      FROM `journals`,`journal_details`,`issue_statuses`
      WHERE `journalized_id` = ? 
      AND `journals`.`id` = `journal_details`.`journal_id` 
      AND `journalized_type` LIKE 'Issue'
      AND `issue_statuses`.`name` LIKE ?
      AND `issue_statuses`.`id` = `journal_details`.`value`
      AND `journal_details`.`prop_key` = 'status_id'
      ORDER BY `journals`.`created_on` DESC
      LIMIT 1", issue.id, @state_name ] ).first;
    if journal != nil
      # convert Time object to Date
      date = Date.parse(journal.created_on.strftime("%Y-%m-%d"))
      value = wc.work_hours(issue.created_on,journal.created_on)
      result = Result.new(date,value)
      results.push(result)
    end
    
    return results
  end
  
end