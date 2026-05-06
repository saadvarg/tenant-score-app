function addFactor(factors, label, impact, detail) {
  factors.push({ label, impact, detail });
}

export function calculateTenantScore(tenant) {
  let score = 100;
  const factors = [];

  const monthlyIncome = Number(tenant.monthly_income || 0);
  const rentAmount = Number(tenant.rent_amount || 0);
  const creditScore = Number(tenant.credit_score || 0);
  const evictionCount = Number(tenant.eviction_count || 0);
  const latePayments = Number(tenant.late_payments || 0);
  const hasCriminalRecord = Boolean(tenant.criminal_record);
  const rentRatio = monthlyIncome > 0 ? rentAmount / monthlyIncome : 1;
  const rentRatioPercent = Math.round(rentRatio * 100);

  if (rentRatio > 0.5) {
    score -= 25;
    addFactor(factors, 'Rent burden', -25, `Rent is ${rentRatioPercent}% of monthly income.`);
  } else if (rentRatio > 0.4) {
    score -= 15;
    addFactor(factors, 'Rent burden', -15, `Rent is ${rentRatioPercent}% of monthly income.`);
  } else if (rentRatio > 0.33) {
    score -= 8;
    addFactor(factors, 'Rent burden', -8, `Rent is ${rentRatioPercent}% of monthly income.`);
  } else {
    addFactor(factors, 'Rent burden', 8, `Rent is ${rentRatioPercent}% of monthly income.`);
  }

  if (creditScore < 580) {
    score -= 25;
    addFactor(factors, 'Credit score', -25, `Credit score is ${creditScore}.`);
  } else if (creditScore < 650) {
    score -= 15;
    addFactor(factors, 'Credit score', -15, `Credit score is ${creditScore}.`);
  } else if (creditScore < 700) {
    score -= 8;
    addFactor(factors, 'Credit score', -8, `Credit score is ${creditScore}.`);
  } else {
    addFactor(factors, 'Credit score', 10, `Credit score is ${creditScore}.`);
  }

  if (evictionCount > 0) {
    const impact = Math.min(evictionCount * 20, 40);
    score -= impact;
    addFactor(factors, 'Eviction history', -impact, `${evictionCount} eviction record(s).`);
  } else {
    addFactor(factors, 'Eviction history', 10, 'No reported evictions.');
  }

  if (latePayments > 0) {
    const impact = Math.min(latePayments * 5, 25);
    score -= impact;
    addFactor(factors, 'Late payments', -impact, `${latePayments} reported late payment(s).`);
  } else {
    addFactor(factors, 'Late payments', 8, 'No reported late payments.');
  }

  if (hasCriminalRecord) {
    score -= 15;
    addFactor(factors, 'Background', -15, 'Criminal record disclosed.');
  } else {
    addFactor(factors, 'Background', 5, 'No criminal record disclosed.');
  }

  switch (tenant.employment_status) {
    case 'unemployed':
      score -= 25;
      addFactor(factors, 'Employment', -25, 'Applicant is currently unemployed.');
      break;
    case 'self_employed':
      score -= 8;
      addFactor(factors, 'Employment', -8, 'Self-employed income should be verified.');
      break;
    case 'student':
      score -= 10;
      addFactor(factors, 'Employment', -10, 'Student income may need guarantor support.');
      break;
    case 'retired':
      score -= 5;
      addFactor(factors, 'Employment', -5, 'Retired applicant may need fixed-income verification.');
      break;
    default:
      addFactor(factors, 'Employment', 8, 'Applicant reports active employment.');
      break;
  }

  const riskScore = Math.max(0, Math.min(100, Math.round(score)));

  if (riskScore >= 75) {
    return {
      risk_score: riskScore,
      risk_level: 'low',
      recommendation: 'approve',
      score_factors: factors,
    };
  }

  if (riskScore >= 50) {
    return {
      risk_score: riskScore,
      risk_level: 'medium',
      recommendation: 'review',
      score_factors: factors,
    };
  }

  return {
    risk_score: riskScore,
    risk_level: 'high',
    recommendation: 'reject',
    score_factors: factors,
  };
}
